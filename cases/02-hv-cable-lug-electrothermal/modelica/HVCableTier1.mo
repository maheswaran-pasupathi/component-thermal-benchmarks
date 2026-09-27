package HVCableTier1
  "Tier 1 1-D electro-thermal model of the front-to-rear HV cable (project 06)"
  extends Modelica.Icons.Package;

  import Modelica.Units.SI;
  import pi = Modelica.Constants.pi;

  model CableAxial
    "HV cable discretised into N axial segments; radial RC stack per node, temperature-dependent conductor resistance, optional axial conduction and junction-box heat sinks"

    // ---------- discretisation ----------
    parameter Integer N(min=2) = 20 "Number of axial segments";
    parameter SI.Length L = 4.5 "Cable route length (one direction)";

    // ---------- conductor (185 mm^2 Al, EN AW-1350) ----------
    parameter SI.Area A = 185e-6 "Conductor cross-section";
    parameter SI.Length d_c = 15.35e-3 "Conductor diameter";
    parameter SI.Length d_out = 21.35e-3 "Cable outer diameter (over jacket)";
    parameter Real rho20 = 2.84e-8 "Al resistivity at 20 degC [ohm.m]";
    parameter Real alpha = 0.00403 "Al temperature coefficient [1/K]";
    parameter SI.Temperature T_ref = 293.15 "Resistivity reference temperature";
    parameter Real k_Al = 237 "Al thermal conductivity [W/(m.K)]";
    parameter Real rho_Al = 2705 "Al density [kg/m3]";
    parameter Real cp_Al = 897 "Al specific heat [J/(kg.K)]";

    // ---------- insulation + jacket (XLPE-class) ----------
    parameter Real k_ins = 0.29 "Combined insulation/jacket conductivity [W/(m.K)]";
    parameter Real rho_ins = 1300 "Insulation+jacket mean density [kg/m3]";
    parameter Real cp_ins = 2000 "Insulation+jacket mean specific heat [J/(kg.K)]";
    parameter Real eps = 0.9 "Jacket emissivity";

    // ---------- surface / ambient ----------
    parameter SI.Temperature[N] T_amb_zone = fill(358.15, N)
      "Zone ambient at each axial station [K] (85 degC default everywhere)";
    parameter SI.Temperature T_amb_end = 353.15
      "Ambient around the junction boxes [K]";
    // still-air natural-convection air properties, fixed at film temp ~385 K (Tier 0 basis)
    parameter Real k_air = 0.0323 "air conductivity [W/(m.K)]";
    parameter Real nu_air = 2.47e-5 "air kinematic viscosity [m2/s]";
    parameter Real a_air = 3.56e-5 "air thermal diffusivity [m2/s]";
    parameter Real beta_air = 1/385 "air expansion coefficient [1/K]";
    constant Real g_acc = 9.81;
    constant Real sigma = 5.670374e-8;

    // ---------- axial conduction / junction boxes ----------
    parameter Boolean axialConduction = true
      "false = isolate segments (recovers the Tier 0 single-node balance)";
    parameter Boolean junctionBoxes = true
      "false = adiabatic cable ends";
    parameter Real C_jb = 1800 "Junction-box busbar+housing heat capacity [J/K]";
    parameter Real G_lug = 6 "Cable-end to JB-busbar thermal conductance [W/K]";
    parameter Real G_jb_amb = 2.5 "JB housing to ambient conductance [W/K]";
    parameter Real R_contact = 30e-6 "Electrical contact resistance per lug joint [ohm]";

    // ---------- initial state ----------
    parameter SI.Temperature T0 = 358.15 "Uniform initial temperature";

    // ---------- current input ----------
    Modelica.Blocks.Interfaces.RealInput I_cable "Cable current [A]"
      annotation(Placement(transformation(extent={{-140,-20},{-100,20}})));

    // ---------- derived ----------
    final parameter SI.Length dx = L/N;
    final parameter SI.Area A_ins = pi/4*(d_out^2 - d_c^2)
      "Insulation+jacket annulus area";
    final parameter Real Rins_pul = log(d_out/d_c)/(2*pi*k_ins)
      "Radial insulation resistance per unit length [K.m/W]";
    final parameter Real C_cond = rho_Al*cp_Al*A*dx "Conductor node heat cap [J/K]";
    final parameter Real C_skin = rho_ins*cp_ins*A_ins*dx "Skin node heat cap [J/K]";
    final parameter Real G_radial = dx/Rins_pul "Conductor->skin conductance [W/K]";
    final parameter Real G_axial = (if axialConduction then k_Al*A/dx else 1e-12)
      "Conductor-to-conductor axial conductance [W/K]";

    // ---------- components ----------
    Modelica.Thermal.HeatTransfer.Components.HeatCapacitor cond[N](
      each C=C_cond, each T(start=T0, fixed=true)) "Conductor segment nodes";
    Modelica.Thermal.HeatTransfer.Components.HeatCapacitor skin[N](
      each C=C_skin, each T(start=T0, fixed=true)) "Insulation surface nodes";
    Modelica.Thermal.HeatTransfer.Components.ThermalConductor radial[N](
      each G=G_radial) "Radial conduction, conductor -> skin";
    Modelica.Thermal.HeatTransfer.Components.ThermalConductor axial[N-1](
      each G=G_axial) "Axial conduction between conductor nodes";
    Modelica.Thermal.HeatTransfer.Components.Convection surf[N]
      "Skin -> ambient, natural convection + radiation (variable Gc)";
    Modelica.Thermal.HeatTransfer.Sources.FixedTemperature amb[N](T=T_amb_zone)
      "Zone ambient";
    Modelica.Thermal.HeatTransfer.Sources.PrescribedHeatFlow gen[N]
      "Joule heat into each conductor node";

    // junction boxes
    Modelica.Thermal.HeatTransfer.Components.HeatCapacitor jbF(
      C=C_jb, T(start=T0, fixed=true)) "Front junction box";
    Modelica.Thermal.HeatTransfer.Components.HeatCapacitor jbR(
      C=C_jb, T(start=T0, fixed=true)) "Rear junction box";
    Modelica.Thermal.HeatTransfer.Components.ThermalConductor lugF(
      G=(if junctionBoxes then G_lug else 1e-12));
    Modelica.Thermal.HeatTransfer.Components.ThermalConductor lugR(
      G=(if junctionBoxes then G_lug else 1e-12));
    Modelica.Thermal.HeatTransfer.Components.ThermalConductor jbAmbF(
      G=(if junctionBoxes then G_jb_amb else 1e-12));
    Modelica.Thermal.HeatTransfer.Components.ThermalConductor jbAmbR(
      G=(if junctionBoxes then G_jb_amb else 1e-12));
    Modelica.Thermal.HeatTransfer.Sources.PrescribedHeatFlow lugHeatF;
    Modelica.Thermal.HeatTransfer.Sources.PrescribedHeatFlow lugHeatR;
    Modelica.Thermal.HeatTransfer.Sources.FixedTemperature ambJBF(T=T_amb_end);
    Modelica.Thermal.HeatTransfer.Sources.FixedTemperature ambJBR(T=T_amb_end);

    // ---------- reported variables ----------
    Real[N] Rprime_pul "Conductor resistance per unit length at local T [ohm/m]";
    Real[N] h_conv "Natural-convection coefficient per segment [W/(m2.K)]";
    Real[N] h_rad "Linearised radiation coefficient per segment [W/(m2.K)]";
    SI.Temperature T_c_max "Peak conductor temperature";
    SI.Temperature T_c_mid "Mid-span conductor temperature";
    SI.Power P_loss "Total Joule loss in this cable";
    SI.Voltage dV "Voltage drop along this cable";

  equation
    for k in 1:N loop
      // temperature-dependent Joule heating
      Rprime_pul[k] = rho20*(1 + alpha*(cond[k].T - T_ref))/A;
      gen[k].Q_flow = I_cable^2*Rprime_pul[k]*dx;
      connect(gen[k].port, cond[k].port);

      // radial stack: conductor -> insulation -> skin -> (conv+rad) -> ambient
      connect(cond[k].port, radial[k].port_a);
      connect(radial[k].port_b, skin[k].port);
      connect(skin[k].port, surf[k].solid);
      connect(surf[k].fluid, amb[k].port);

      // surface coefficients (Churchill-Chu natural convection + grey-body radiation)
      h_conv[k] = (0.60 + 0.3206*(g_acc*beta_air*max(0.5, skin[k].T - T_amb_zone[k])
                   *d_out^3/(nu_air*a_air))^(1/6))^2 * k_air/d_out;
      h_rad[k]  = eps*sigma*(skin[k].T^2 + T_amb_zone[k]^2)*(skin[k].T + T_amb_zone[k]);
      surf[k].Gc = (h_conv[k] + h_rad[k])*pi*d_out*dx;
    end for;

    for k in 1:N-1 loop
      connect(cond[k].port, axial[k].port_a);
      connect(axial[k].port_b, cond[k+1].port);
    end for;

    // junction boxes and lug contact heating
    lugHeatF.Q_flow = (if junctionBoxes then I_cable^2*R_contact else 0);
    lugHeatR.Q_flow = (if junctionBoxes then I_cable^2*R_contact else 0);
    connect(lugHeatF.port, cond[1].port);
    connect(lugHeatR.port, cond[N].port);
    connect(jbF.port, lugF.port_a);
    connect(lugF.port_b, cond[1].port);
    connect(jbR.port, lugR.port_a);
    connect(lugR.port_b, cond[N].port);
    connect(jbF.port, jbAmbF.port_a);
    connect(jbAmbF.port_b, ambJBF.port);
    connect(jbR.port, jbAmbR.port_a);
    connect(jbAmbR.port_b, ambJBR.port);

    // reporting
    T_c_max = max(cond.T);
    T_c_mid = cond[integer(N/2)].T;
    P_loss  = sum(gen.Q_flow);
    dV      = I_cable*sum(Rprime_pul)*dx;

    annotation(
      Icon(coordinateSystem(preserveAspectRatio=false), graphics={
        Rectangle(extent={{-100,30},{100,-30}}, lineColor={95,95,95},
          fillColor={205,140,60}, fillPattern=FillPattern.HorizontalCylinder),
        Rectangle(extent={{-100,16},{100,-16}}, lineColor={95,95,95},
          fillColor={230,200,120}, fillPattern=FillPattern.HorizontalCylinder),
        Rectangle(extent={{-94,44},{-70,-44}}, lineColor={0,0,0},
          fillColor={160,160,160}, fillPattern=FillPattern.Solid),
        Rectangle(extent={{70,44},{94,-44}}, lineColor={0,0,0},
          fillColor={160,160,160}, fillPattern=FillPattern.Solid),
        Text(extent={{-90,-30},{-58,-52}}, textString="front JB"),
        Text(extent={{58,-30},{92,-52}}, textString="rear JB"),
        Text(extent={{-100,90},{100,50}}, textString="%name", textColor={0,0,255}),
        Text(extent={{-100,-58},{100,-84}},
          textString="1-D electro-thermal, N=%N seg")}),
      Documentation(info="<html>
<p>Tier 1 of project 06. One HV cable run, N axial segments. Each segment: a
conductor heat-capacity node with temperature-dependent Joule heating, a radial
conduction resistance to an insulation-surface node, and a combined
convection+radiation path to the local zone ambient. Optional axial conduction
between conductor nodes and lumped junction-box heat sinks with lug contact
heating at the two ends.</p>
<p>Set <code>axialConduction=false, junctionBoxes=false</code> and a uniform
<code>T_amb_zone</code> to recover the Tier 0 single-node steady balance for
validation.</p></html>"));
  end CableAxial;


  model SteadyValidation
    "Constant 500 A, uniform 85 degC, no axial conduction / JB - must reproduce Tier 0"
    extends Modelica.Icons.Example;
    CableAxial cable(
      N=20, axialConduction=false, junctionBoxes=false,
      T_amb_zone=fill(358.15, 20))
      annotation(Placement(transformation(extent={{0,-20},{40,20}})));
    Modelica.Blocks.Sources.Constant I500(k=500)
      annotation(Placement(transformation(extent={{-60,-10},{-40,10}})));
  equation
    connect(I500.y, cable.I_cable)
      annotation(Line(points={{-39,0},{-2,0}}, color={0,0,127}));
    annotation(experiment(StopTime=6000, Interval=5, Tolerance=1e-6),
      Documentation(info="<html><p>Acceptance criterion 1: steady
<code>cable.T_c_mid</code> should sit near the Tier 0 value (~140-142 degC at
500 A for 185 mm^2 Al) and the implied ampacity within ~3 %.</p></html>"));
  end SteadyValidation;


  model AmpacityCheck
    "Slow integral control drives the mid conductor node to 150 degC; I_amp settles at the ampacity"
    extends Modelica.Icons.Example;
    CableAxial cable(
      N=20, axialConduction=false, junctionBoxes=false,
      T_amb_zone=fill(358.15, 20))
      annotation(Placement(transformation(extent={{0,-20},{40,20}})));
    parameter SI.Temperature T_lim = 423.15 "Conductor limit (150 degC)";
    parameter Real gain = 0.15 "Integral gain [A/(K.s)]";
    Real I_amp(start=520, fixed=true) "Ampacity [A]";
  equation
    der(I_amp) = gain*(T_lim - cable.T_c_mid);
    cable.I_cable = I_amp;
    annotation(experiment(StopTime=15000, Interval=10, Tolerance=1e-6),
      Documentation(info="<html><p>Inverse solve by feedback: <code>I_amp</code> is
integrated so the mid conductor node converges to 150 degC. Its settled value is
the Tier 1 continuous ampacity - compare with Tier 0's ~533 A. Gain is kept well
below the cable thermal rate so the loop is stable.</p></html>"));
  end AmpacityCheck;


  model Mission
    "Full model over a representative duty cycle with a hot mid-route zone"
    extends Modelica.Icons.Example;
    // hotter 85 degC middle third of the run, cooler 70 degC near the boxes
    CableAxial cable(
      N=20, axialConduction=true, junctionBoxes=true,
      T_amb_zone={343.15,343.15,343.15,348.15,348.15,353.15,358.15,358.15,358.15,358.15,
                  358.15,358.15,358.15,358.15,353.15,348.15,348.15,343.15,343.15,343.15},
      T_amb_end=343.15)
      annotation(Placement(transformation(extent={{0,-20},{40,20}})));
    // representative mission: rated cruise -> sustained gradient pull -> peak overtake -> cruise
    Modelica.Blocks.Sources.TimeTable Imission(table=[
      0,    420;
      1200, 420;
      1200, 500;
      3000, 500;
      3000, 667;
      3180, 667;
      3180, 400;
      5400, 400])
      annotation(Placement(transformation(extent={{-60,-10},{-40,10}})));
  equation
    connect(Imission.y, cable.I_cable)
      annotation(Line(points={{-39,0},{-2,0}}, color={0,0,127}));
    annotation(experiment(StopTime=5400, Interval=5, Tolerance=1e-6),
      Documentation(info="<html><p>Outputs <code>cable.T_c_max</code> and the full
<code>cable.cond[:].T</code> field: hot-spot location, peak temperature, time to
the 150 degC limit, and cycle voltage drop. Acceptance criterion 2: peak
<code>T_c</code> over the mission stays below 150 degC for 185 mm^2 Al, or the
section is revised.</p></html>"));
  end Mission;

  annotation(uses(Modelica(version="4.1.0")));
end HVCableTier1;

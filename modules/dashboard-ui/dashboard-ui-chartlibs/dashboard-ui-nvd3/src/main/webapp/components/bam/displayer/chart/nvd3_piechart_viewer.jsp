<%--

    Copyright (C) 2012 JBoss Inc

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

          http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

--%>

<%
    NVD3ChartViewer viewer = (NVD3ChartViewer) Factory.lookup("org.jboss.dashboard.ui.components.PieChartViewer_nvd3");
%>
<%@ page import="org.jboss.dashboard.factory.Factory" %>
<%@ page import="org.jboss.dashboard.ui.components.chart.NVD3ChartViewer" %>
<%@ page import="org.jboss.dashboard.displayer.chart.AbstractChartDisplayer" %>
<%@ page import="org.jboss.dashboard.displayer.chart.AbstractXAxisDisplayer" %>
<%@ page import="org.jboss.dashboard.ui.components.AbstractChartDisplayerEditor" %>
<%@ page import="org.jboss.dashboard.dataset.DataSet" %>
<%@ page import="org.jboss.dashboard.domain.Interval" %>
<%@ page import="org.jboss.dashboard.provider.DataProperty"%>
<%@ page import="java.util.ArrayList" %>
<%@ page import="java.util.List" %>
<%@ page import="java.util.Locale" %>
<%@ page import="java.text.DecimalFormat" %>
<%@ page import="org.jboss.dashboard.LocaleManager" %>
<%@ page import="org.jboss.dashboard.commons.text.StringUtil" %>
<%@ taglib uri="mvc_taglib.tld" prefix="mvc"%>
<%@ taglib uri="factory.tld" prefix="factory" %>
<%@ taglib uri="bui_taglib.tld" prefix="panel"  %>
<%@ taglib uri="http://jakarta.apache.org/taglibs/i18n-1.0" prefix="i18n" %>
<%
    AbstractChartDisplayer displayer = (AbstractChartDisplayer) viewer.getDataDisplayer();

    DataSet xyDataSet = null;
    if( displayer != null ) {
        xyDataSet = displayer.buildXYDataSet();
    }

    AbstractChartDisplayerEditor editor = (AbstractChartDisplayerEditor) request.getAttribute("editor");
    boolean animateChart = (editor == null);
    boolean enableDrillDown = (editor == null);
    boolean enableTooltips  = (editor == null);

    if (xyDataSet == null) {
%>
<span class="skn-error">The data cannot be displayed due to an unexpected problem.</span>
<%
       return;
    }

    DataProperty domainProperty = displayer.getDomainProperty();
    DataProperty rangeProperty = displayer.getRangeProperty();
    Locale locale = LocaleManager.currentLocale();
    DecimalFormat numberFormat = (DecimalFormat) DecimalFormat.getInstance(Locale.US);
    numberFormat.setGroupingUsed(false);
    List<String> xvalues = new ArrayList<String>();
    List<String> yvalues = new ArrayList<String>();
    double minDsValue = -1;
    double maxDsValue = -1;

    for (int i=0; i< xyDataSet.getRowCount(); i++) {
        String xvalue = ((Interval) xyDataSet.getValueAt(i, 0)).getDescription(locale);
        double yvalue = ((Number) xyDataSet.getValueAt(i, 1)).doubleValue();

        xvalues.add(StringUtil.escapeQuotes(xvalue));
        yvalues.add(numberFormat.format(yvalue));

        // Get the minimum and the maximum value of the dataset.
        if ((minDsValue == -1) || (yvalue < minDsValue)) minDsValue = yvalue;
        if ((maxDsValue == -1) || (yvalue > maxDsValue)) maxDsValue = yvalue;
    }

    // Every chart must have a different identifier so as to do not merge tooltips.
    int suffix = viewer.hashCode();
    if (suffix < 0) suffix *= -1;
    String chartId = viewer.getComponentAlias() + suffix;
%>

<form method="post" action='<factory:formUrl friendly="false"/>' id='<%="form"+chartId%>'>
  <factory:handler bean="<%=viewer.getComponentName()%>" action="<%= NVD3ChartViewer.PARAM_ACTION %>"/>
  <input type="hidden" name="<%= NVD3ChartViewer.PARAM_NSERIE %>" value="0" />
</form>


<table class="skn-chart-table" width="100%">
    <tbody>
    <tr>
        <td width="<%= displayer.getWidth() %>" height="<%= displayer.getHeight() %>" align="<%=displayer.getGraphicAlign()%>">
<% if( displayer.isShowTitle() && displayer.getTitle() != null) { %>
            <div id="title<%=chartId%>"   class="skn-chart-title"><%=displayer.getTitle()%></div>
<% } %>
            <div id="tooltip<%=chartId%>" class="skn-chart-tooltip"></div>
            <div class="skn-chart-wrapper" style="width:<%= displayer.getWidth() %>px;height:<%= displayer.getHeight() %>px" id="<%= chartId %>">
                <svg></svg>
            </div>
        </td>
    </tr>
    </tbody>
</table>

<script>
    chartData<%=chartId%> = [
        {
            key: "<%= displayer.getTitle() %>",
            values: [
                <% for(int i=0; i < xvalues.size(); i++) { if( i != 0 ) out.print(", "); %>
                {
                    "label" : "<%= xvalues.get(i) %>" ,
                    "value" : <%= yvalues.get(i) %>
                }
                <% } %>
            ]
        }
    ];

    nv.addGraph({
      generate: function() {
            var chart = nv.models.pieChart();

             chart  .x(function(d) { return d.label })
                    .y(function(d) { return d.value })
                    .width(<%= displayer.getWidth() %>)
                    .height(<%= displayer.getHeight() %>)
                    .showLegend(true)
                    .tooltips(true)
<% if(!enableTooltips) { %>

                    .showLabels(true)
<% } %>
                    .margin({top: <%=displayer.getMarginTop()%>, right: <%=displayer.getMarginRight()%>, bottom: <%=displayer.getMarginBottom()%>, left: <%=displayer.getMarginLeft()%>});

               d3.select('#<%= chartId %> svg')
                    .datum(chartData<%=chartId%>)
<% if(animateChart) { %> .transition().duration(1200) <% } %>
                    .call(chart);

               nv.utils.windowResize(chart.update);

            return chart;

      },
      callback: function(graph) {
       <% if( enableDrillDown ) {%>
          graph.pie.dispatch.on('elementClick', function(e) {
          form = document.getElementById('<%="form"+chartId%>');
          form.<%= NVD3ChartViewer.PARAM_NSERIE %>.value = e.index;
          submitAjaxForm(form);
          });
       <% } %>
      }
  });
</script>

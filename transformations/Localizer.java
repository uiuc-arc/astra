package grammar.transformations;

import grammar.AST;
import grammar.Template3Listener;
import grammar.Template3Parser;
import grammar.cfg.CFGBuilder;
import grammar.cfg.Section;
import org.antlr.v4.runtime.ParserRuleContext;
import org.antlr.v4.runtime.Token;
import org.antlr.v4.runtime.TokenStreamRewriter;
import org.antlr.v4.runtime.tree.ErrorNode;
import org.antlr.v4.runtime.tree.ParseTree;
import org.antlr.v4.runtime.tree.TerminalNode;
import utils.Utils;

import javax.json.JsonArray;
import javax.json.JsonObject;
import javax.json.JsonValue;
import java.util.ArrayList;
import java.util.List;

public class Localizer implements Template3Listener {
    private final List<JsonObject> models= Utils.getDistributions(null);
    public TokenStreamRewriter antlrRewriter;
    public ArrayList<Section> sections;
    public Boolean existNext=true;
    private Token lastDeclStop;
    private int paramToTransform;
    private ArrayList<String> dataList = new ArrayList<>();
    private String dimMatch;
    private String iMatch;
    private Boolean inFor_loop = false;
    private ArrayList<String> priorAdded = new ArrayList<>();
    private Token startLastAssign;
    private Boolean startTransformedparam=false;

    public Localizer(CFGBuilder cfgBuilder, TokenStreamRewriter antlrRewriter, int paramToTransform) {
        this.antlrRewriter = antlrRewriter;
        this.sections = cfgBuilder.getSections();
        this.paramToTransform = paramToTransform;
    }

    @Override
    public void enterPrimitive(Template3Parser.PrimitiveContext ctx) {

    }

    @Override
    public void exitPrimitive(Template3Parser.PrimitiveContext ctx) {

    }

    @Override
    public void enterNumber(Template3Parser.NumberContext ctx) {

    }

    @Override
    public void exitNumber(Template3Parser.NumberContext ctx) {

    }

    @Override
    public void enterLimits(Template3Parser.LimitsContext ctx) {

    }

    @Override
    public void exitLimits(Template3Parser.LimitsContext ctx) {

    }

    @Override
    public void enterMarker(Template3Parser.MarkerContext ctx) {

    }

    @Override
    public void exitMarker(Template3Parser.MarkerContext ctx) {

    }

    @Override
    public void enterAnnotation_type(Template3Parser.Annotation_typeContext ctx) {

    }

    @Override
    public void exitAnnotation_type(Template3Parser.Annotation_typeContext ctx) {

    }

    @Override
    public void enterAnnotation_value(Template3Parser.Annotation_valueContext ctx) {

    }

    @Override
    public void exitAnnotation_value(Template3Parser.Annotation_valueContext ctx) {

    }

    @Override
    public void enterAnnotation(Template3Parser.AnnotationContext ctx) {

    }

    @Override
    public void exitAnnotation(Template3Parser.AnnotationContext ctx) {

    }

    @Override
    public void enterDims(Template3Parser.DimsContext ctx) {

    }

    @Override
    public void exitDims(Template3Parser.DimsContext ctx) {

    }

    @Override
    public void enterDim(Template3Parser.DimContext ctx) {

    }

    @Override
    public void exitDim(Template3Parser.DimContext ctx) {

    }

    @Override
    public void enterDtype(Template3Parser.DtypeContext ctx) {

    }

    @Override
    public void exitDtype(Template3Parser.DtypeContext ctx) {

    }

    @Override
    public void enterArray(Template3Parser.ArrayContext ctx) {

    }

    @Override
    public void exitArray(Template3Parser.ArrayContext ctx) {

    }

    @Override
    public void enterVector(Template3Parser.VectorContext ctx) {

    }

    @Override
    public void exitVector(Template3Parser.VectorContext ctx) {

    }

    @Override
    public void enterData(Template3Parser.DataContext ctx) {
        dataList.add(ctx.decl.ID.getText());

    }

    @Override
    public void exitData(Template3Parser.DataContext ctx) {

    }

    @Override
    public void enterFunction_call(Template3Parser.Function_callContext ctx) {
        if (inFor_loop) {
            ArrayList<AST.Expression> params = ctx.value.parameters;
            if (params.size() > 1 && !ctx.ID.getText().equals("cov_exp_quad") && !ctx.ID.getText().equals("log_mix")) {
                if (dataList.contains(params.get(0).toString().split("\\[")[0]) && ctx.e2 != null) {
                    ParserRuleContext paramToTransformCtx = ctx.expr(1 + paramToTransform);
                    String newParamName = "robust_local_" + paramToTransformCtx.getText().replaceAll("[^a-zA-Z0-9_]", "").replaceAll(iMatch,"");
                    // replace original_param
                    antlrRewriter.replace(paramToTransformCtx.getStart(), paramToTransformCtx.getStop(), String.format("%1$s[%2$s]", newParamName,  iMatch));
                    // Add decl for robust_local_param
                    String limits = findLimits(ctx.ID.getText().replace("_lpdf","").replace("_lpmf",""), paramToTransform);
                    if (!priorAdded.contains(newParamName)) {
                        // Add robust_local_param prior normal(original_param, 0.25)
                        // antlrRewriter.insertBefore(startLastAssign, String.format("%1$s[%2$s] = normal(%3$s, 0.25)\n", newParamName,  iMatch, paramToTransformCtx.getText()));
                        // antlrRewriter.insertAfter(lastDeclStop, String.format("\n\n@prior\n@limits %3$s\nfloat %1$s[%2$s]\n\n", newParamName, dimMatch, limits));
                        antlrRewriter.insertBefore(startLastAssign, String.format("%1$s[%2$s] = normal(%3$s, robust_local_hyperp)\n", newParamName,  iMatch, paramToTransformCtx.getText()));
                        antlrRewriter.insertAfter(lastDeclStop, String.format("\n\n@prior\n@limits<lower=0,upper=1>\nfloat robust_local_hyperp\n\n@prior\n@limits %3$s\nfloat %1$s[%2$s]\n\n", newParamName, dimMatch, limits));
                        priorAdded.add(newParamName);
                    }

                    if (ctx.expr().size() <= 2 + paramToTransform) {
                        existNext = false;
                    }
                    System.out.println("==============================Current: " + ctx.getText() );
                    System.out.println("==============================Exist Next: " + existNext );

                }

            }

        }

    }

    private String findLimits(String functionID, int paramToTransform) {
        String lower = null;
        String upper = null;
        String ret = "";
        for (JsonObject model : this.models) {
            if (functionID.equals(model.getString("name"))) {
                JsonArray modelParams = model.getJsonArray("args");
                JsonValue currParam = modelParams.get(paramToTransform);
                String paramType = currParam.asJsonObject().getString("type");
                if (paramType.contains("+")) {
                    lower = "lower=0";
                    if (functionID.contains("normal") && paramToTransform == 1)
                        upper = "upper=10";
                } else if (paramType.contains("p")){
                    lower = "lower=0";
                    upper = "upper=1";
                }
                break;
            }
        }
        if (upper != null && lower != null) {ret = "<" + lower + "," + upper + ">";}
        else if (lower != null) {ret = "<" + lower + ">"; }
        return ret;
    }

    @Override
    public void exitFunction_call(Template3Parser.Function_callContext ctx) {

    }

    @Override
    public void enterFor_loop(Template3Parser.For_loopContext ctx) {
        this.dimMatch = ctx.e2.getText();
        this.iMatch = ctx.value.loopVar.id;
        this.inFor_loop = true;

    }

    @Override
    public void exitFor_loop(Template3Parser.For_loopContext ctx) {
        this.inFor_loop = false;

    }

    @Override
    public void enterIf_stmt(Template3Parser.If_stmtContext ctx) {

    }

    @Override
    public void exitIf_stmt(Template3Parser.If_stmtContext ctx) {

    }

    @Override
    public void enterAssign(Template3Parser.AssignContext ctx) {
        startLastAssign = ctx.getStart();

    }

    @Override
    public void exitAssign(Template3Parser.AssignContext ctx) {

    }

    @Override
    public void enterDecl(Template3Parser.DeclContext ctx) {

    }

    @Override
    public void exitDecl(Template3Parser.DeclContext ctx) {
        for (AST.Annotation annotation: ctx.value.annotations) {
            if (annotation.annotationType == AST.AnnotationType.Prior) {
                lastDeclStop = ctx.getStop();
            }
        }

    }

    @Override
    public void enterStatement(Template3Parser.StatementContext ctx) {

    }

    @Override
    public void exitStatement(Template3Parser.StatementContext ctx) {

    }

    @Override
    public void enterBlock(Template3Parser.BlockContext ctx) {

    }

    @Override
    public void exitBlock(Template3Parser.BlockContext ctx) {

    }

    @Override
    public void enterExpr(Template3Parser.ExprContext ctx) {

    }

    @Override
    public void exitExpr(Template3Parser.ExprContext ctx) {

    }

    @Override
    public void enterQuery(Template3Parser.QueryContext ctx) {

    }

    @Override
    public void exitQuery(Template3Parser.QueryContext ctx) {

    }

    @Override
    public void enterTemplate(Template3Parser.TemplateContext ctx) {

    }

    @Override
    public void exitTemplate(Template3Parser.TemplateContext ctx) {

    }

    @Override
    public void visitTerminal(TerminalNode terminalNode) {

    }

    @Override
    public void visitErrorNode(ErrorNode errorNode) {

    }

    @Override
    public void enterEveryRule(ParserRuleContext parserRuleContext) {

    }

    @Override
    public void exitEveryRule(ParserRuleContext parserRuleContext) {

    }
}

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
import org.antlr.v4.runtime.tree.TerminalNode;

import java.util.ArrayList;

public class MixNormal implements Template3Listener {
    private final TokenStreamRewriter antlrRewriter;
    public ArrayList<Section> sections;
    public Boolean transformed=false;
    private Token lastDeclStop;
    private ArrayList<String> dataList = new ArrayList<>();
    private String dimMatch;
    private String iMatch;
    private Boolean inFor_loop = false;
    private Boolean isPriorAdded = false;
    private Boolean isMixture = false;
    private Token startLastAssign;

    public MixNormal(CFGBuilder cfgBuilder, TokenStreamRewriter antlrRewriter) {
        this.antlrRewriter = antlrRewriter;
        this.sections = cfgBuilder.getSections();
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
        if (ctx.getText().contains("log_mix"))
            isMixture=true;
        if (!isMixture && inFor_loop && ! isPriorAdded && ctx.ID.getText().contains("normal_lpdf")) {
            String orgSigma = ctx.getChild(6).getText();
            String orgDist = ctx.getText();
            String outlierDist = orgDist.replace(orgSigma, "sqrt(exp(robust_outlier_log_var))");
            antlrRewriter.replace(ctx.getStart(),ctx.getStop(),
                    String.format("log_mix(robust_prob_outlier, %1$s, %2$s)", outlierDist, orgDist));
            antlrRewriter.insertBefore(startLastAssign, "robust_outlier_log_var=normal(robust_outlier_log_var_mu,robust_outlier_log_var_std)\n");
            antlrRewriter.insertAfter(lastDeclStop,
                    String.format("\n@prior\n@limits %2$s\nfloat %1$s\n", "robust_prob_outlier", "<lower=0,upper=0.5>"));
            if (orgSigma.contains("]")) {
                antlrRewriter.insertAfter(lastDeclStop,
                        String.format("\n@prior\n@limits %2$s\nfloat %1$s\n", "robust_outlier_log_var",
                                "<lower=log(max(" + orgSigma.replaceAll("\\[.*]","") + ")^2)>"));
            } else {
                antlrRewriter.insertAfter(lastDeclStop,
                        String.format("\n@prior\n@limits %2$s\nfloat %1$s\n", "robust_outlier_log_var", "<lower=log((" + orgSigma + ")^2)>"));
            }
            antlrRewriter.insertAfter(lastDeclStop,
                    String.format("\n@prior\n@limits %2$s\nfloat %1$s\n", "robust_outlier_log_var_mu", ""));
            antlrRewriter.insertAfter(lastDeclStop,
                    String.format("\n@prior\n@limits %2$s\nfloat %1$s\n", "robust_outlier_log_var_std", "<lower=0>"));
            isPriorAdded = true;
            transformed = true;
        }
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

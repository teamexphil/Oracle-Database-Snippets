DECLARE

l_xml XMLTYPE;
l_xsl XMLTYPE;
l_transformed XMLTYPE;

BEGIN

   l_xml := XMLTYPE('<?xml version="1.0"?><DATA><CUSTOMER><FIRSTNAME>Meg</FIRSTNAME><SURNAME>McDonald</SURNAME><INTEREST>Baking</INTEREST></CUSTOMER><CUSTOMER><FIRSTNAME>Philip</FIRSTNAME><SURNAME>McDonald</SURNAME><INTEREST>Kayaking</INTEREST></CUSTOMER></DATA>');

   l_xsl := XMLTYPE('<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"><xsl:template match="/"> <html><body> <xsl:for-each select="DATA/CUSTOMER"> <h2><xsl:value-of select="FIRSTNAME"/></h2> <p><xsl:value-of select="INTEREST"/></p></xsl:for-each> </body></html></xsl:template></xsl:stylesheet>');

   SELECT XMLTRANSFORM(l_xml, l_xsl)
   INTO l_transformed
   FROM dual;

   DBMS_OUTPUT.PUT_LINE(l_transformed.getstringval());

END;
/

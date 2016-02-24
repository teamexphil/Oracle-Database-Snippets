create or replace package p_filter_query is

  -- Author  : PHIL
  -- Created : 23/02/2016 09:40:45
  -- Purpose : To allow parsing and formatting of xmltype documents
  
  /*
  begin
  -- Call the procedure
    p_filter_query.filterquery('CUSTOMER',
                            p_formatting.createFilterXml('<surname>McDonald</surname>') );
  end;*/
  
  function isValidXml(p_input varchar2, p_xml_out out xmltype) return boolean;

  procedure filterQuery(p_table varchar2, p_filter xmltype);
  
  function createFilterXml(p_filter varchar2) return xmltype;
    
end p_filter_query;

create or replace package body p_filter_query is

  -- TODO : output to refcursor which could be read by a client e.g. java program
    
  procedure out(p_string varchar2) is
    
  begin
    dbms_output.put_line(p_string);  
  end;
  
  function isValidXml(p_input varchar2, p_xml_out out xmltype) return boolean is 
  
    l_xml xmltype;
  begin 
    out('Input: ' || p_input);
    l_xml := xmltype(p_input);
    out('Output: '|| to_char(l_xml.getClobVal()));
    p_xml_out := l_xml;
    return true;
  exception
    when others then
      out('Could not convert to xml...');
      out(p_input);
      return false;  
  end;
  
  function selectListForTable (p_table varchar2) return varchar2 is
    l_select varchar2(2000) := 'SELECT';
    l_first boolean := true;
  begin
      
    for col in (select utc.COLUMN_NAME
                from user_tab_columns utc
                where utc.table_name = p_table) LOOP
      if l_first then
        l_first := false;
      else
        l_select := l_select || ',';  
      end if;
              
      l_select := l_select || ' ' || col.column_name;            
    end loop;            
    
    l_select := l_select || ' FROM ' || p_table;
    return l_select;
  end;
  
  function  dump_csv_dbms_output( p_query        in varchar2,
                                  p_separator in varchar2 default ',')
  return number
  is
      l_theCursor     integer default dbms_sql.open_cursor;
      l_columnValue   varchar2(2000);
      l_output_line   varchar2(2000);
      l_status        integer;
      l_colCnt        number default 0;
      l_separator     varchar2(10) default '';
      l_cnt           number default 0;
  begin
    out('Parsing');
    dbms_sql.parse(  l_theCursor,  p_query, dbms_sql.native );
      
    for i in 1 .. 255 loop
      begin
        dbms_sql.define_column( l_theCursor, i,
                                       l_columnValue, 2000 );
        l_colCnt := i;
      exception
        when others then
          --out(sqlerrm || ' ' || sqlcode);
          if ( sqlcode = -1007 ) then exit;
          else
            raise;
          end if;
      end;
    end loop;
   
    out('Execute sql');
    l_status := dbms_sql.execute(l_theCursor);
  
    loop
      exit when ( dbms_sql.fetch_rows(l_theCursor) <= 0 );
        l_separator := '';
        for i in 1 .. l_colCnt loop
          dbms_sql.column_value( l_theCursor, i,
                                   l_columnValue );
          l_output_line := l_output_line || l_separator || l_columnValue;
          l_separator := p_separator;
        end loop;
      l_cnt := l_cnt+1;
      out(l_output_line);
      l_output_line := '';
    end loop;
    dbms_sql.close_cursor(l_theCursor);
  
    return l_cnt;
  end dump_csv_dbms_output;

  procedure filterQuery(p_table varchar2, p_filter xmltype) is
    l_elem varchar2(1000);
    l_elem_val varchar2(1000);
    l_where varchar2(2000) := 'WHERE ';
    l_rows number;
  begin   
    for nodes in (select xmlsequence(extract(p_filter,'filter/*')) as node from dual) loop -- get one row of xmlsequencetype collection containing inner nodes and values
      for i in nodes.node.first .. nodes.node.last loop
        
        select nodes.node(i).getRootElement()
        into l_elem
        from dual;
        
        select extractvalue(nodes.node(i),'/'||l_elem)
        into l_elem_val
        from dual;    
        
        out(l_elem || ':' || l_elem_val);
        if i!=1 then
          l_where := l_where || ' and ';
        end if;  
        l_where := l_where || l_elem || ' = ''' || l_elem_val || '''';
      end loop;  
    end loop;
      
    out(selectListForTable(p_table) || ' ' || l_where);
    
    l_rows := dump_csv_dbms_output(selectListForTable(p_table) || ' ' || l_where);
  end;
  
  function createFilterXml(p_filter varchar2) return xmltype is
    l_str varchar2(2000);
  begin
    l_str := '<filter>' || p_filter || '</filter>';
    return xmltype(l_str);  
  end;
  
begin
  null;
end p_filter_query;

<%@ page import="java.sql.*" %>
<%@ page import="java.text.NumberFormat" %>
<%@ page import="java.util.HashMap" %>
<%@ page import="java.util.Iterator" %>
<%@ page import="java.util.ArrayList" %>
<%@ page import="java.util.Map" %>
<%@ include file="jdbc.jsp" %>

<html>
<HEAD>
<TITLE>Mikey.ca | Order Processing</TITLE>
 <link href="shift.css" rel="stylesheet">
 <link href="bootstrap.css" rel="stylesheet">
 <link href="main.css" rel="stylesheet">
</HEAD>
<body>
        
<%@ include file="header.jsp" %>

<%
// Get customer id
/* String custId = request.getParameter("customerId"); */
int TypeID = Integer.parseInt(request.getParameter("TypeID"));  

// Get password
String password = request.getParameter("password");
// Get shopping cart
@SuppressWarnings({"unchecked"})
HashMap<String, ArrayList<Object>> productList = (HashMap<String, ArrayList<Object>>) session.getAttribute("productList");
                
try 
{	
	if (authenticatedUser == null || authenticatedUser.equals(""))
		out.println("<h1>Invalid customer id.  Go back to the previous page and try again.</h1>");
	else if (productList == null || productList.isEmpty())
		out.println("<h1>Your shopping cart is empty!</h1>");
	else
	{	
		// Check if customer id is a number
		int num=-1;
		try
		{
			num = Integer.parseInt(authenticatedUser);
		} 
		catch(Exception e)
		{
			out.println("<h1>Invalid customer id.  Go back to the previous page and try again.</h1>");
			return;
		}		
        
		// Get database connection
        getConnection();
	                		
        /* String sql = "SELECT UserID, cname, password FROM Users WHERE UserID = ?";	 */
        String sql = "SELECT UserID, fname, lname, password, address, city, province, postalcode, GETDATE() as odate, DATEADD(day,2,GETDATE()) as sdate FROM Users WHERE UserID = ?";
				      
   		/* con = DriverManager.getConnection(url, uid, pwd); */
   		PreparedStatement pstmt = con.prepareStatement(sql);
   		pstmt.setInt(1, num);
   		ResultSet rst = pstmt.executeQuery();
   		int orderId=0;
   		String custName = "";

   		if (!rst.next())
   		{
   			out.println("<h1>Invalid customer id.  Go back to the previous page and try again.</h1>");
   		}
   		else
   		{	
   			custName = rst.getString("fname") + " " + rst.getString("lname");
			String dbpassword = rst.getString("password");
				    		
			/* // make sure the password on the database is the same as the one the user entered
			if (!dbpassword.equals(password)) 
			{
				out.println("The password you entered was not correct.  Please go back and try again.<br>"); 
				return;
			} */
			
   			// Enter order information into database
   			sql = "INSERT INTO Orders (UserID, TotalAmount, TypeID, odate, address, city, province, postalcode, sdate) VALUES(?, 0, ?, ?, ?, ?, ?, ?, ?);";
   			// Retrieve auto-generated key for orderId
   			pstmt = con.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS);
   			pstmt.setInt(1, num);
   			pstmt.setInt(2, TypeID);
			pstmt.setString(3, rst.getString("odate"));
			pstmt.setString(4, rst.getString("address"));
			pstmt.setString(5, rst.getString("city"));
			pstmt.setString(6, rst.getString("province"));
			pstmt.setString(7, rst.getString("postalcode"));
			pstmt.setString(8, rst.getString("sdate"));
   			pstmt.executeUpdate();
   			ResultSet keys = pstmt.getGeneratedKeys();
   			keys.next();
   			orderId = keys.getInt(1);

   			out.println("<h1>Your Order Summary</h1>");
         	  	out.println("<table><tr><th>Product Id</th><th>Product Name</th><th>Quantity</th><th>Price</th><th>Subtotal</th></tr>");

           	double total =0;
           	Iterator<Map.Entry<String, ArrayList<Object>>> iterator = productList.entrySet().iterator();
           	NumberFormat currFormat = NumberFormat.getCurrencyInstance();
						
           	while (iterator.hasNext())
           	{ 
           		Map.Entry<String, ArrayList<Object>> entry = iterator.next();
                   ArrayList<Object> product = (ArrayList<Object>) entry.getValue();
   				String productId = (String) product.get(0);
                   out.print("<tr><td>"+productId+"</td>");
                   out.print("<td>"+product.get(1)+"</td>");
   				out.print("<td align=\"center\">"+product.get(3)+"</td>");
                   String price = (String) product.get(2);
                   double pr = Double.parseDouble(price);
                   int qty = ( (Integer)product.get(3)).intValue();
   				out.print("<td align=\"right\">"+currFormat.format(pr)+"</td>");
                  	out.print("<td align=\"right\">"+currFormat.format(pr*qty)+"</td></tr>");
                   out.println("</tr>");
                   total = total +pr*qty;

   				sql = "INSERT INTO OrderedProduct (oid, pid, quantity, price) VALUES( ?, ?, ?, ?)";
   				pstmt = con.prepareStatement(sql);
   			 	pstmt.setInt(1, orderId); 
   				pstmt.setInt(2, Integer.parseInt(productId));
   				pstmt.setInt(3, qty);
   				pstmt.setDouble(4, Double.parseDouble(price));
   				pstmt.executeUpdate();				
           	}
           	out.println("<tr><td colspan=\"4\" align=\"right\"><b>Order Total</b></td>"
                          	+"<td aling=\"right\">"+currFormat.format(total)+"</td></tr>");
           	out.println("</table>");

   			// Update order total
   			sql = "UPDATE Orders SET TotalAmount=? WHERE oid=?";
   			pstmt = con.prepareStatement(sql);
   			pstmt.setDouble(1, total);
   			pstmt.setInt(2, orderId);			
   			pstmt.executeUpdate();						

   			out.println("<h1>Order completed.  Will be shipped on this date: " +rst.getString("sdate") + "</h1>");
   			out.println("<h1>Your order reference number is: "+orderId+"</h1>");
   			out.println("<h1>Shipping to customer id: "+authenticatedUser+", Name: "+custName+"</h1>");

   			// Clear session variables (cart)
   			session.setAttribute("productList", null);    
   		}
   	}
}
catch (SQLException ex)
{ 	out.println(ex);
}
finally
{
	try
	{
		if (con != null)
			con.close();
	}
	catch (SQLException ex)
	{       out.println(ex);
	}
}  
%>                       				

<h2><a href="Home.jsp">Back to Main Page</a></h2>

</body>
</html>

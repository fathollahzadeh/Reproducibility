
WITH RecursiveTagCounts AS (
    SELECT 
        unnest(string_to_array(substring(Tags, 2, length(Tags)-2), '><')) AS TagName,
        COUNT(*) AS PostCount
    FROM 
        Posts
    WHERE 
        PostTypeId = 1  
    GROUP BY 
        TagName
),
ActiveUsers AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COALESCE(SUM(V.BountyAmount), 0) AS TotalBounties,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT C.Id) AS TotalComments
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    WHERE 
        U.Reputation > 100  
    GROUP BY 
        U.Id, U.DisplayName
),
PopularTags AS (
    SELECT 
        TagName,
        PostCount
    FROM 
        RecursiveTagCounts
    ORDER BY 
        PostCount DESC
    LIMIT 10  
)
SELECT 
    AU.DisplayName,
    AU.TotalPosts,
    AU.TotalComments,
    AU.TotalBounties,
    PT.TagName,
    PT.PostCount
FROM 
    ActiveUsers AU
JOIN 
    PopularTags PT ON AU.TotalPosts > 5  
ORDER BY 
    AU.TotalBounties DESC, AU.TotalPosts DESC;

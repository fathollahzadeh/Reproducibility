WITH TagStats AS (
    SELECT 
        T.TagName,
        COUNT(DISTINCT P.Id) AS PostCount,
        COUNT(DISTINCT C.Id) AS CommentCount,
        COUNT(DISTINCT A.Id) AS AnswerCount,
        SUM(P.ViewCount) AS TotalViews
    FROM 
        Tags T
    LEFT JOIN 
        Posts P ON P.Tags LIKE '%' || T.TagName || '%'
    LEFT JOIN 
        Comments C ON C.PostId = P.Id
    LEFT JOIN 
        Posts A ON A.ParentId = P.Id AND A.PostTypeId = 2 
    WHERE 
        P.PostTypeId = 1
    GROUP BY 
        T.TagName
),
UserReputation AS (
    SELECT 
        U.Id AS UserId,
        SUM(B.Class) AS TotalBadgeClasses,
        AVG(U.Reputation) AS AvgReputation
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON B.UserId = U.Id
    GROUP BY 
        U.Id
),
TopTags AS (
    SELECT 
        TS.TagName,
        TS.PostCount,
        TS.CommentCount,
        TS.AnswerCount,
        TS.TotalViews,
        R.TotalBadgeClasses,
        R.AvgReputation
    FROM 
        TagStats TS
    LEFT JOIN 
        UserReputation R ON R.UserId = (SELECT OwnerUserId FROM Posts P WHERE P.Tags LIKE '%' || TS.TagName || '%' LIMIT 1)
    ORDER BY 
        TS.PostCount DESC
    LIMIT 10
)
SELECT 
    TT.TagName,
    TT.PostCount,
    TT.CommentCount,
    TT.AnswerCount,
    TT.TotalViews,
    TT.TotalBadgeClasses,
    TT.AvgReputation
FROM 
    TopTags TT
WHERE 
    TT.PostCount > 5
AND 
    TT.AvgReputation > 50
ORDER BY 
    TT.TotalViews DESC;

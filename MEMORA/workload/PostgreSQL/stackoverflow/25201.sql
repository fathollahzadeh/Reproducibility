WITH TagCounts AS (
    SELECT 
        TRIM(UNNEST(string_to_array(SUBSTRING(Tags, 2, LENGTH(Tags) - 2), '><'))) AS TagName,
        COUNT(*) AS PostCount
    FROM 
        Posts
    WHERE 
        PostTypeId = 1 
    GROUP BY 
        TagName
), 
TopTags AS (
    SELECT 
        TagName,
        PostCount,
        RANK() OVER (ORDER BY PostCount DESC) AS Rank
    FROM 
        TagCounts
    WHERE 
        PostCount > 1
), 
UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        SUM(CASE WHEN P.OwnerUserId = U.Id THEN P.Score ELSE 0 END) AS TotalScore,
        SUM(B.Class) AS BadgeScore
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id, U.DisplayName
    HAVING 
        SUM(P.Score) > 0 OR SUM(B.Class) > 0
)
SELECT 
    TT.TagName,
    TT.PostCount,
    UR.DisplayName,
    UR.TotalScore,
    UR.BadgeScore
FROM 
    TopTags TT
JOIN 
    UserReputation UR ON UR.TotalScore > (SELECT AVG(TotalScore) FROM UserReputation)
WHERE 
    TT.Rank <= 10
ORDER BY 
    TT.PostCount DESC, 
    UR.TotalScore DESC;
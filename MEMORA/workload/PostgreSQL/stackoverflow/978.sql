
WITH UserPostCounts AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id, U.DisplayName
),
PopularTags AS (
    SELECT 
        T.TagName,
        COUNT(P.Id) AS PostCount
    FROM 
        Tags T
    JOIN 
        Posts P ON P.Tags LIKE CONCAT('%', T.TagName, '%')
    GROUP BY 
        T.TagName
    HAVING 
        COUNT(P.Id) > 10
),
RecentVotes AS (
    SELECT 
        V.PostId,
        COUNT(V.Id) AS VoteCount
    FROM 
        Votes V
    WHERE 
        V.CreationDate >= (CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '30 days')
    GROUP BY 
        V.PostId
)

SELECT 
    UPC.UserId,
    UPC.DisplayName,
    UPC.TotalPosts,
    UPC.Questions,
    UPC.Answers,
    COALESCE(PV.VoteCount, 0) AS RecentVoteCount,
    PT.TagName
FROM 
    UserPostCounts UPC
LEFT JOIN 
    RecentVotes PV ON PV.PostId IN (SELECT Id FROM Posts WHERE OwnerUserId = UPC.UserId)
LEFT JOIN 
    PopularTags PT ON PT.PostCount > 0
WHERE 
    UPC.TotalPosts > 5
ORDER BY 
    UPC.TotalPosts DESC, RecentVoteCount DESC
LIMIT 10 OFFSET 0;

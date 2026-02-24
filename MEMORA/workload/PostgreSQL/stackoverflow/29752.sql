
WITH PostStatistics AS (
    SELECT
        P.Id AS PostId,
        P.Title,
        P.Body,
        ARRAY_LENGTH(string_to_array(P.Tags, '>'), 1) AS TagCount,
        COALESCE(AC.AnswerCount, 0) AS AnswerCount,
        COALESCE(SUM(V.BountyAmount), 0) AS TotalBounties
    FROM 
        Posts P
    LEFT JOIN (
        SELECT 
            ParentId,
            COUNT(*) AS AnswerCount
        FROM 
            Posts
        WHERE 
            PostTypeId = 2
        GROUP BY 
            ParentId
    ) AS AC ON P.Id = AC.ParentId
    LEFT JOIN Votes V ON P.Id = V.PostId AND V.VoteTypeId IN (8, 9)
    WHERE 
        P.PostTypeId = 1 
    GROUP BY 
        P.Id, P.Title, P.Body, AC.AnswerCount
),
TopPosts AS (
    SELECT 
        PS.PostId,
        PS.Title,
        PS.TagCount,
        PS.AnswerCount,
        PS.TotalBounties,
        RANK() OVER (ORDER BY PS.TotalBounties DESC, PS.AnswerCount DESC) AS Rank
    FROM 
        PostStatistics PS
)
SELECT 
    TP.Title,
    TP.TagCount,
    TP.AnswerCount,
    TP.TotalBounties,
    U.DisplayName AS TopContributor
FROM 
    TopPosts TP
JOIN 
    Users U ON (
        SELECT 
            OwnerUserId 
        FROM 
            Posts 
        WHERE 
            Id = TP.PostId
        LIMIT 1
    ) = U.Id
WHERE 
    TP.Rank <= 10
ORDER BY 
    TP.Rank;

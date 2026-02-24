WITH RankedPosts AS (
    SELECT
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
        COUNT(A.Id) AS AnswerCount,
        P.Tags,
        U.Reputation AS OwnerReputation
    FROM
        Posts P
    LEFT JOIN
        Comments C ON C.PostId = P.Id
    LEFT JOIN
        Posts A ON A.ParentId = P.Id AND A.PostTypeId = 2
    LEFT JOIN
        Users U ON U.Id = P.OwnerUserId
    WHERE
        P.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year' 
    GROUP BY
        P.Id, U.Reputation
),
PostStatistics AS (
    SELECT
        COUNT(*) AS TotalPosts,
        AVG(ViewCount) AS AvgViewCount,
        AVG(Score) AS AvgScore,
        SUM(CommentCount) AS TotalComments,
        SUM(AnswerCount) AS TotalAnswers,
        AVG(OwnerReputation) AS AvgOwnerReputation
    FROM
        RankedPosts
)
SELECT
    RS.*,
    PS.*
FROM
    RankedPosts RS,
    PostStatistics PS
ORDER BY
    RS.Score DESC, RS.ViewCount DESC;
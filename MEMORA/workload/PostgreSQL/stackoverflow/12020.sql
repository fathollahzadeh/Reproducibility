
WITH PostStatistics AS (
    SELECT
        P.PostTypeId,
        COUNT(P.Id) AS PostCount,
        AVG(P.Score) AS AvgScore,
        SUM(P.ViewCount) AS TotalViews,
        SUM(P.AnswerCount) AS TotalAnswers,
        SUM(P.CommentCount) AS TotalComments,
        SUM(P.FavoriteCount) AS TotalFavorites,
        MAX(P.CreationDate) AS LastPostDate
    FROM
        Posts P
    WHERE
        P.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'  
    GROUP BY
        P.PostTypeId
),
UserEngagement AS (
    SELECT
        U.Id AS UserId,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes
    FROM
        Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Votes V ON P.Id = V.PostId
    GROUP BY 
        U.Id, U.Reputation
)

SELECT
    PST.PostTypeId,
    PST.PostCount,
    PST.AvgScore,
    PST.TotalViews,
    PST.TotalAnswers,
    PST.TotalComments,
    PST.TotalFavorites,
    PST.LastPostDate,
    SUM(UE.TotalPosts) AS TotalUserPosts,
    AVG(UE.Reputation) AS AvgUserReputation,
    SUM(UE.TotalUpVotes) AS TotalUserUpVotes,
    SUM(UE.TotalDownVotes) AS TotalUserDownVotes
FROM
    PostStatistics PST
JOIN
    UserEngagement UE ON PST.PostCount > 0  
GROUP BY
    PST.PostTypeId, PST.PostCount, PST.AvgScore, PST.TotalViews,
    PST.TotalAnswers, PST.TotalComments, PST.TotalFavorites, PST.LastPostDate
ORDER BY
    PST.PostTypeId;

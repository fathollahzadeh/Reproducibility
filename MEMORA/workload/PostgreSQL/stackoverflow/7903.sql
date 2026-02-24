
WITH UserVoteStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(V.Id) AS TotalVotes
    FROM 
        Users U
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    GROUP BY 
        U.Id, U.DisplayName
),
PostAnswerSummary AS (
    SELECT 
        P.OwnerUserId,
        COUNT(P.Id) AS AnswerCount,
        AVG(P.Score) AS AverageScore,
        SUM(P.ViewCount) AS TotalViews
    FROM 
        Posts P
    WHERE 
        P.PostTypeId = 2
    GROUP BY 
        P.OwnerUserId
),
TopUsers AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COALESCE(PA.AnswerCount, 0) AS AnswerCount,
        COALESCE(PA.AverageScore, 0) AS AverageScore,
        COALESCE(PA.TotalViews, 0) AS TotalViews,
        COALESCE(UV.UpVotes, 0) AS UpVotes,
        COALESCE(UV.DownVotes, 0) AS DownVotes
    FROM 
        Users U
    LEFT JOIN 
        PostAnswerSummary PA ON U.Id = PA.OwnerUserId
    LEFT JOIN 
        UserVoteStats UV ON U.Id = UV.UserId
    ORDER BY 
        U.Reputation DESC
    LIMIT 10
)
SELECT 
    TU.UserId,
    TU.DisplayName,
    TU.Reputation,
    TU.AnswerCount,
    TU.AverageScore,
    TU.TotalViews,
    TU.UpVotes,
    TU.DownVotes
FROM 
    TopUsers TU;

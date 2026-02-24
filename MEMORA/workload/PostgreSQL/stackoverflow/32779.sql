WITH RECURSIVE UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(P.Id) AS QuestionCount,
        COALESCE(SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END), 0) AS AnswerCount,
        SUM(COALESCE(P.ViewCount, 0)) AS TotalViews,
        SUM(COALESCE(P.Score, 0)) AS TotalScore,
        ROW_NUMBER() OVER (PARTITION BY U.Id ORDER BY SUM(P.ViewCount) DESC) AS ActivityRank
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    WHERE 
        U.Reputation > 1000
    GROUP BY 
        U.Id, U.DisplayName
),
RecentVotes AS (
    SELECT 
        V.UserId,
        COUNT(V.Id) AS VoteCount,
        SUM(CASE WHEN VT.Name = 'UpMod' THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN VT.Name = 'DownMod' THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes V
    JOIN 
        VoteTypes VT ON V.VoteTypeId = VT.Id
    WHERE 
        V.CreationDate >= cast('2024-10-01' as date) - INTERVAL '30 days'
    GROUP BY 
        V.UserId
),
UserRankings AS (
    SELECT 
        UA.UserId,
        UA.DisplayName,
        UA.QuestionCount,
        UA.AnswerCount,
        UA.TotalViews,
        UA.TotalScore,
        RV.VoteCount,
        RV.UpVotes,
        RV.DownVotes,
        RANK() OVER (ORDER BY UA.TotalScore DESC) AS OverallRank
    FROM 
        UserActivity UA
    LEFT JOIN 
        RecentVotes RV ON UA.UserId = RV.UserId
)

SELECT 
    UR.DisplayName,
    UR.QuestionCount,
    UR.AnswerCount,
    UR.TotalViews,
    UR.TotalScore,
    COALESCE(UR.VoteCount, 0) AS VoteCount,
    COALESCE(UR.UpVotes, 0) AS UpVotes,
    COALESCE(UR.DownVotes, 0) AS DownVotes,
    UR.OverallRank
FROM 
    UserRankings UR
WHERE 
    UR.OverallRank <= 10
ORDER BY 
    UR.TotalScore DESC;
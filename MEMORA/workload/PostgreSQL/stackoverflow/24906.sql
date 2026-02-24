
WITH UserVoteSummary AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT CASE WHEN P.PostTypeId = 1 THEN P.Id END) AS Questions,
        COUNT(DISTINCT CASE WHEN P.PostTypeId = 2 THEN P.Id END) AS Answers,
        ROW_NUMBER() OVER (ORDER BY SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) DESC) AS Rank
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        U.Id, U.DisplayName
),
RecentCloseReasons AS (
    SELECT 
        PH.UserId,
        COUNT(*) AS CloseCount,
        STRING_AGG(DISTINCT CRT.Name || ' (' || PH.CreationDate || ')', ', ') AS CloseReasons
    FROM 
        PostHistory PH
    JOIN 
        CloseReasonTypes CRT ON CAST(PH.Comment AS INTEGER) = CRT.Id
    WHERE 
        PH.PostHistoryTypeId IN (10, 11) 
    GROUP BY 
        PH.UserId
),
UserPerformance AS (
    SELECT 
        U.Id AS UserId,
        COALESCE(SUM(CASE WHEN P.PostTypeId = 1 THEN P.Score END), 0) AS TotalQuestionScore,
        COALESCE(SUM(CASE WHEN P.PostTypeId = 2 THEN P.Score END), 0) AS TotalAnswerScore,
        U.Reputation,
        COUNT(DISTINCT B.Id) AS BadgeCount,
        COALESCE(RC.CloseCount, 0) AS CloseReasonsCount,
        COALESCE(RC.CloseReasons, 'None') AS RecentCloseReasons
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    LEFT JOIN 
        RecentCloseReasons RC ON U.Id = RC.UserId
    GROUP BY 
        U.Id, U.Reputation, RC.CloseCount, RC.CloseReasons
)
SELECT 
    UPS.UserId,
    UPS.TotalQuestionScore,
    UPS.TotalAnswerScore,
    UPS.Reputation,
    UPS.BadgeCount,
    UPS.CloseReasonsCount,
    UPS.RecentCloseReasons,
    UDS.UpVotes,
    UDS.DownVotes,
    UDS.Rank
FROM 
    UserPerformance UPS
LEFT JOIN 
    UserVoteSummary UDS ON UPS.UserId = UDS.UserId
WHERE 
    UPS.Reputation > 100
ORDER BY 
    UPS.Reputation DESC,
    UPS.TotalQuestionScore DESC;

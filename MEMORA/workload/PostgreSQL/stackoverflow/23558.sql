
WITH CTE_UserVoteStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        DENSE_RANK() OVER (ORDER BY COUNT(DISTINCT P.Id) DESC) AS PostRank
    FROM 
        Users U
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    LEFT JOIN 
        Posts P ON V.PostId = P.Id
    GROUP BY 
        U.Id, U.DisplayName
), CTE_ClosedPosts AS (
    SELECT 
        PH.PostId,
        COUNT(PH.Id) AS CloseCount,
        STRING_AGG(CRT.Name, ', ') AS CloseReasons
    FROM 
        PostHistory PH
    JOIN 
        PostHistoryTypes PHT ON PH.PostHistoryTypeId = PHT.Id
    JOIN 
        CloseReasonTypes CRT ON CAST(PH.Comment AS integer) = CRT.Id
    WHERE 
        PHT.Name = 'Post Closed'
    GROUP BY 
        PH.PostId
), CTE_AcceptedAnswers AS (
    SELECT 
        P.Id AS PostId,
        COUNT(A.Id) AS AcceptedAnswerCount
    FROM 
        Posts P
    LEFT JOIN 
        Posts A ON P.AcceptedAnswerId = A.Id
    WHERE 
        P.PostTypeId = 1 
    GROUP BY 
        P.Id
)
SELECT 
    U.DisplayName,
    U.Reputation,
    COALESCE(UV.UpVotes, 0) AS UpVotes,
    COALESCE(UV.DownVotes, 0) AS DownVotes,
    COALESCE(UV.TotalPosts, 0) AS TotalPosts,
    COALESCE(CP.CloseCount, 0) AS CloseCount,
    COALESCE(CP.CloseReasons, 'None') AS CloseReasons,
    COALESCE(AA.AcceptedAnswerCount, 0) AS AcceptedAnswerCount,
    CASE 
        WHEN COALESCE(UV.TotalPosts, 0) = 0 THEN 'No Posts'
        WHEN COALESCE(UV.UpVotes, 0) > COALESCE(UV.DownVotes, 0) THEN 'Positive Contributor'
        ELSE 'Needs Improvement' 
    END AS UserContributionStatus
FROM 
    Users U
LEFT JOIN 
    CTE_UserVoteStats UV ON U.Id = UV.UserId
LEFT JOIN 
    CTE_ClosedPosts CP ON U.Id = CP.PostId
LEFT JOIN 
    CTE_AcceptedAnswers AA ON U.Id = AA.PostId
WHERE 
    (U.Reputation >= 100 OR (UV.UpVotes IS NOT NULL AND UV.DownVotes IS NULL))
ORDER BY 
    UserContributionStatus, U.DisplayName;

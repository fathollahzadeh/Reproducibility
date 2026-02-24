
WITH PostScoreSummary AS (
    SELECT 
        P.Id AS PostId,
        SUM(CASE 
            WHEN V.VoteTypeId = 2 THEN 1
            WHEN V.VoteTypeId = 3 THEN -1
            ELSE 0 
        END) AS NetScore,
        COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) AS DownVotes
    FROM 
        Posts P
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    WHERE 
        P.CreationDate >= (CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year') 
    GROUP BY 
        P.Id
),

ClosedPostAnalysis AS (
    SELECT 
        PH.PostId, 
        COUNT(*) AS CloseCount,
        STRING_AGG(CAST(PH.CreationDate AS VARCHAR), ', ' ORDER BY PH.CreationDate) AS CloseDates,
        MAX(PH.CreationDate) AS LastCloseDate
    FROM 
        PostHistory PH
    WHERE 
        PH.PostHistoryTypeId = 10
    GROUP BY 
        PH.PostId
),

UserPostStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        SUM(COALESCE(PS.NetScore, 0)) AS TotalScore,
        SUM(CASE WHEN PS.NetScore > 0 THEN 1 ELSE 0 END) AS PositivePosts,
        SUM(CASE WHEN PS.NetScore < 0 THEN 1 ELSE 0 END) AS NegativePosts
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        PostScoreSummary PS ON P.Id = PS.PostId
    GROUP BY 
        U.Id, U.DisplayName
),

FinalResults AS (
    SELECT 
        U.UserId,
        U.DisplayName,
        U.TotalPosts,
        U.TotalScore,
        U.PositivePosts,
        U.NegativePosts,
        CPA.CloseCount,
        CPA.CloseDates,
        CPA.LastCloseDate
    FROM 
        UserPostStats U
    LEFT JOIN 
        ClosedPostAnalysis CPA ON U.UserId = CPA.PostId 
    ORDER BY 
        U.TotalScore DESC, 
        U.TotalPosts DESC
)

SELECT 
    FR.*,
    CASE 
        WHEN FR.CloseCount IS NOT NULL THEN 'Closed Post Activity Exists'
        ELSE 'No Closed Posts'
    END AS PostActivityStatus,
    COALESCE(CAST(FR.LastCloseDate AS VARCHAR), 'N/A') AS LastCloseDateFormatted
FROM 
    FinalResults FR
WHERE 
    (FR.TotalScore > 10 OR FR.PositivePosts > 5) 
    AND FR.UserId IS NOT NULL
    AND (FR.CloseCount IS NULL OR FR.TotalPosts > 1) 
ORDER BY 
    FR.UserId;

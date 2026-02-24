WITH UserVotingStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) AS DownVotes,
        SUM(COALESCE(P.Score, 0)) AS TotalScore,
        SUM(COALESCE(P.ViewCount, 0)) AS TotalViews
    FROM 
        Users U
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    LEFT JOIN 
        Posts P ON V.PostId = P.Id
    GROUP BY 
        U.Id, U.DisplayName
),
PostHistoryDetails AS (
    SELECT 
        PH.PostId,
        MAX(CASE WHEN PH.PostHistoryTypeId = 10 THEN PH.UserId END) AS LastClosedBy,
        MAX(CASE WHEN PH.PostHistoryTypeId = 11 THEN PH.UserId END) AS LastReopenedBy,
        COUNT(DISTINCT PH.Id) AS EditCount
    FROM 
        PostHistory PH
    GROUP BY 
        PH.PostId
),
MaxEditDetails AS (
    SELECT 
        PostId,
        LastClosedBy,
        LastReopenedBy,
        EditCount,
        ROW_NUMBER() OVER (PARTITION BY LastClosedBy ORDER BY EditCount DESC) AS RN
    FROM 
        PostHistoryDetails
    WHERE 
        LastClosedBy IS NOT NULL
)

SELECT 
    U.DisplayName,
    U.TotalScore,
    U.TotalViews,
    P.Title,
    P.CreationDate,
    COALESCE(ED.LastClosedBy, ED.LastReopenedBy) AS LastActionBy,
    ED.EditCount
FROM 
    UserVotingStats U
JOIN 
    Posts P ON U.UserId = P.OwnerUserId
LEFT JOIN 
    MaxEditDetails ED ON ED.PostId = P.Id
WHERE 
    U.TotalScore > 100 
    AND (P.CreationDate > cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year' OR P.ViewCount > 500)
ORDER BY 
    U.TotalViews DESC, U.TotalScore DESC
LIMIT 50;
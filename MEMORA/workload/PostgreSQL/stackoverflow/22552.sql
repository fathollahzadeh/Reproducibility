WITH UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COALESCE(SUM(p.ViewCount), 0) AS TotalViews,
        COUNT(DISTINCT p.Id) AS PostCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
RankedUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        UpVotes,
        DownVotes,
        TotalViews,
        PostCount,
        ROW_NUMBER() OVER (ORDER BY Reputation DESC) AS ReputationRank,
        RANK() OVER (ORDER BY TotalViews DESC) AS ViewRank
    FROM 
        UserStatistics
),
FilteredUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        UpVotes,
        DownVotes,
        TotalViews,
        PostCount,
        ReputationRank,
        ViewRank
    FROM 
        RankedUsers
    WHERE 
        PostCount > 5
),
CloseReasonSummary AS (
    SELECT 
        postHistory.UserId,
        COUNT(CASE WHEN postHistory.PostHistoryTypeId = 10 THEN 1 END) AS CloseCount,
        COUNT(CASE WHEN postHistory.PostHistoryTypeId = 11 THEN 1 END) AS ReopenCount
    FROM 
        PostHistory postHistory
    GROUP BY 
        postHistory.UserId
),
FinalResult AS (
    SELECT 
        f.UserId,
        f.DisplayName,
        f.Reputation,
        f.UpVotes,
        f.DownVotes,
        f.TotalViews,
        f.PostCount,
        COALESCE(c.CloseCount, 0) AS TotalCloseActions,
        COALESCE(c.ReopenCount, 0) AS TotalReopenActions
    FROM 
        FilteredUsers f
    LEFT JOIN 
        CloseReasonSummary c ON f.UserId = c.UserId
)
SELECT 
    *,
    CASE 
        WHEN Reputation > 1000 THEN 'High Reputation'
        WHEN Reputation BETWEEN 500 AND 1000 THEN 'Medium Reputation'
        ELSE 'Low Reputation'
    END AS ReputationCategory,
    CASE 
        WHEN PostCount > 10 THEN 'Frequent Contributor'
        ELSE 'Occasional Contributor'
    END AS ContributionType
FROM 
    FinalResult
WHERE 
    (TotalCloseActions > 3 OR TotalReopenActions > 3)
ORDER BY 
    Reputation DESC, TotalViews DESC;
WITH RankedUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        ROW_NUMBER() OVER (PARTITION BY CASE 
                                              WHEN u.Reputation < 1000 THEN 'Novice'
                                              WHEN u.Reputation BETWEEN 1000 AND 5000 THEN 'Intermediate'
                                              ELSE 'Expert'
                                          END 
                                          ORDER BY u.Reputation DESC) AS Rank
    FROM 
        Users u
    WHERE 
        u.LastAccessDate >= cast('2024-10-01' as date) - INTERVAL '1 year'
),

PostScoreDetails AS (
    SELECT 
        p.Id AS PostId,
        p.OwnerUserId,
        COUNT(c.Id) AS CommentCount,
        SUM(COALESCE(v.BountyAmount, 0)) AS TotalBounty,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        p.Score,
        p.Title
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 month'
        AND p.PostTypeId IN (1, 2)  
    GROUP BY 
        p.Id
),

PostHistorySummary AS (
    SELECT 
        ph.PostId,
        COUNT(CASE WHEN ph.PostHistoryTypeId IN (10, 11, 12, 13) THEN 1 END) AS CloseReopenCount,
        MAX(ph.CreationDate) AS LastActionDate
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
),

FinalResults AS (
    SELECT 
        pu.DisplayName AS UserDisplayName,
        ps.PostId,
        ps.Title,
        ps.CommentCount,
        ps.TotalBounty,
        ps.UpVotes,
        ps.DownVotes,
        ps.Score,
        COALESCE(p_summary.CloseReopenCount, 0) AS CloseReopenCount,
        p_summary.LastActionDate,
        CASE 
            WHEN pu.Rank = 1 THEN 'Novice Contributor'
            WHEN pu.Rank = 2 THEN 'Intermediate Contributor'
            WHEN pu.Rank = 3 THEN 'Expert Contributor'
            ELSE 'Unknown Contributor'
        END AS ContributorLevel
    FROM 
        PostScoreDetails ps
    LEFT JOIN 
        RankedUsers pu ON ps.OwnerUserId = pu.UserId
    LEFT JOIN 
        PostHistorySummary p_summary ON ps.PostId = p_summary.PostId
    WHERE 
        ps.Score > 0 
        AND pu.UserId IS NOT NULL
    ORDER BY 
        ps.Score DESC, pu.Reputation DESC
)

SELECT 
    *,
    CONCAT(UserDisplayName, ' - ', ContributorLevel) AS FullDisplay,
    CASE 
        WHEN CloseReopenCount > 5 THEN 'Highly Active'
        ELSE 'Regular Activity'
    END AS ActivityStatus 
FROM 
    FinalResults
WHERE 
    LastActionDate IS NOT NULL
ORDER BY 
    CloseReopenCount DESC, Title;
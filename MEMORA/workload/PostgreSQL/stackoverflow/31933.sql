
WITH RecursivePostHistory AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        ph.UserId,
        ph.PostHistoryTypeId,
        ph.Comment,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS rn
    FROM 
        PostHistory ph
), 
PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate AS PostCreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        COALESCE(ph.Comment, 'No Comments') AS LastComment,
        COALESCE(ph.CreationDate, '2023-01-01') AS LastCommentDate,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY ph.CreationDate DESC) AS LastCommentRank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        RecursivePostHistory ph ON p.Id = ph.PostId AND ph.rn = 1
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
), 
BadgesSummary AS (
    SELECT 
        UserId,
        COUNT(*) AS BadgeCount,
        STRING_AGG(Name, ', ') AS Badges
    FROM 
        Badges
    GROUP BY 
        UserId
), 
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        bi.BadgeCount,
        bi.Badges
    FROM 
        Users u
    LEFT JOIN 
        BadgesSummary bi ON u.Id = bi.UserId
    WHERE 
        u.Reputation > 1000
    ORDER BY 
        u.Reputation DESC
    LIMIT 10
)

SELECT 
    pd.PostId,
    pd.Title,
    pd.PostCreationDate,
    pd.Score,
    pd.ViewCount,
    pd.OwnerDisplayName,
    pd.LastComment,
    pd.LastCommentDate,
    tu.DisplayName AS TopUserDisplayName,
    tu.Reputation AS TopUserReputation,
    tu.BadgeCount,
    tu.Badges
FROM 
    PostDetails pd
JOIN 
    TopUsers tu ON pd.OwnerDisplayName = tu.DisplayName
WHERE 
    pd.LastCommentRank = 1
ORDER BY 
    pd.Score DESC, pd.ViewCount DESC;

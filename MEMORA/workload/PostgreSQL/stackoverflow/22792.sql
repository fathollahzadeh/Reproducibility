
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS RankScore,
        DENSE_RANK() OVER (ORDER BY p.CreationDate DESC) AS RankAge
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= (CAST('2024-10-01' AS DATE) - INTERVAL '1 year')
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Votes v ON v.UserId = u.Id
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
    HAVING 
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) > 10
),
PostHistories AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        ph.CreationDate,
        ph.UserDisplayName,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate) AS ChronologicalOrder
    FROM 
        PostHistory ph
    WHERE 
        ph.CreationDate >= (CAST('2024-10-01' AS DATE) - INTERVAL '6 months')
),
EligiblePosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        pu.DisplayName AS TopUser,
        ph.UserDisplayName AS LastEditor
    FROM 
        RankedPosts rp
    LEFT JOIN 
        TopUsers pu ON pu.PostCount >= 5 
    LEFT JOIN 
        PostHistories ph ON rp.PostId = ph.PostId
    WHERE 
        RankScore <= 10 
        AND RankAge <= 5 
)
SELECT 
    ep.PostId,
    ep.Title,
    ep.Score,
    ep.ViewCount,
    COALESCE(ep.TopUser, 'No Top User') AS TopUser,
    COALESCE(ep.LastEditor, 'No Last Editor') AS LastEditor,
    COUNT(DISTINCT c.Id) AS TotalComments
FROM 
    EligiblePosts ep
LEFT JOIN 
    Comments c ON ep.PostId = c.PostId
GROUP BY 
    ep.PostId, ep.Title, ep.Score, ep.ViewCount, ep.TopUser, ep.LastEditor
ORDER BY 
    ep.Score DESC,
    TotalComments DESC;

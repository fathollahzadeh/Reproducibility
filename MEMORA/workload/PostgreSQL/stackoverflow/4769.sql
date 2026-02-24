WITH RankedPosts AS (
    SELECT 
        p.Id, 
        p.Title, 
        p.CreationDate, 
        p.Score, 
        p.ViewCount, 
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) as Rank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount
), 
UserScore AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(v.BountyAmount) AS TotalBounty,
        AVG(u.Reputation) AS AvgReputation
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.DisplayName
), 
PostDetails AS (
    SELECT 
        rp.Id AS PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.CommentCount,
        us.UserId,
        us.DisplayName AS UserDisplayName,
        us.TotalBounty,
        us.AvgReputation
    FROM 
        RankedPosts rp
    LEFT JOIN 
        Posts p ON rp.Id = p.Id
    LEFT JOIN 
        UserScore us ON p.OwnerUserId = us.UserId
    WHERE 
        rp.Rank <= 10
)

SELECT 
    pd.Title,
    pd.CreationDate,
    pd.Score,
    pd.ViewCount,
    pd.CommentCount,
    COALESCE(pd.UserDisplayName, 'Anonymous') AS OwnerDisplayName,
    pd.TotalBounty,
    pd.AvgReputation
FROM 
    PostDetails pd
WHERE 
    pd.TotalBounty IS NOT NULL 
    OR pd.AvgReputation > 100
ORDER BY 
    pd.Score DESC, pd.ViewCount DESC;
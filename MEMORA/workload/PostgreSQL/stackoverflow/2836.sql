WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS UserRank,
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.OwnerUserId, p.Title, p.CreationDate, p.Score, p.ViewCount
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(v.BountyAmount) AS TotalBounty
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    WHERE 
        u.Reputation > 1000
    GROUP BY 
        u.Id, u.DisplayName
),
PostDetails AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.ViewCount,
        rp.Score,
        tp.Id AS PostTypeId,
        tp.Name AS PostTypeName,
        CASE 
            WHEN rp.UserRank = 1 THEN 'Top Post'
            ELSE 'Regular Post'
        END AS RankDescription
    FROM 
        RankedPosts rp
    JOIN 
        PostTypes tp ON rp.PostId = tp.Id
)
SELECT 
    pd.PostId,
    pd.Title,
    pd.CreationDate,
    pd.ViewCount,
    pd.Score,
    pd.PostTypeName,
    COALESCE(u.DisplayName, 'Unknown User') AS UserName,
    COALESCE(u.TotalBounty, 0) AS UserBounty,
    pd.RankDescription,
    CASE 
        WHEN pd.Score IS NULL OR pd.Score < 0 THEN 'Needs Attention'
        ELSE 'Performing Well'
    END AS PostPerformance
FROM 
    PostDetails pd
LEFT JOIN 
    TopUsers u ON pd.PostId IN (SELECT PostId FROM Votes WHERE UserId = u.UserId)
WHERE 
    pd.ViewCount > 100
ORDER BY 
    pd.Score DESC, pd.CreationDate DESC;
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year'
),
AggregatedUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty,
        SUM(u.UpVotes - u.DownVotes) AS Score
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id
),
PostDetails AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.ViewCount,
        rp.Score,
        au.UserId,
        au.DisplayName,
        au.BadgeCount,
        au.TotalBounty,
        au.Score AS UserScore,
        CASE 
            WHEN rp.Score >= 100 THEN 'High'
            WHEN rp.Score BETWEEN 50 AND 99 THEN 'Medium'
            ELSE 'Low'
        END AS ScoreCategory
    FROM 
        RankedPosts rp
    JOIN 
        Posts p ON rp.PostId = p.Id
    JOIN 
        AggregatedUsers au ON p.OwnerUserId = au.UserId
    WHERE 
        rp.Rank <= 10
)
SELECT 
    pd.Title,
    pd.CreationDate,
    pd.ViewCount,
    pd.Score,
    pd.DisplayName AS Author,
    pd.BadgeCount,
    pd.TotalBounty,
    pd.ScoreCategory,
    (SELECT COUNT(*) FROM Comments c WHERE c.PostId = pd.PostId) AS CommentCount,
    (SELECT COUNT(*) FROM Votes v WHERE v.PostId = pd.PostId AND v.VoteTypeId = 2) AS UpVoteCount
FROM 
    PostDetails pd
ORDER BY 
    pd.Score DESC, pd.CreationDate DESC;
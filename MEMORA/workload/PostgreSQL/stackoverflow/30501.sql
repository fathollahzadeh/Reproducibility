WITH RecursivePostStats AS (
    SELECT 
        p.Id AS PostId,
        p.OwnerUserId,
        p.Title,
        p.CreationDate,
        p.LastActivityDate,
        p.Score,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT ph.Id) AS EditCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.LastActivityDate DESC) AS UserPostRank
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 8  
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId AND ph.PostHistoryTypeId IN (4, 5, 6)  
    GROUP BY 
        p.Id, p.OwnerUserId, p.Title, p.CreationDate, p.LastActivityDate, p.Score
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
FilteredPosts AS (
    SELECT 
        ps.PostId,
        ps.Title,
        ps.CreationDate,
        ps.LastActivityDate,
        ps.Score,
        ps.TotalBounty,
        ps.CommentCount,
        ub.BadgeCount,
        ub.BadgeNames
    FROM 
        RecursivePostStats ps
    JOIN 
        Users u ON ps.OwnerUserId = u.Id
    LEFT JOIN 
        UserBadges ub ON ub.UserId = ps.OwnerUserId
    WHERE 
        ps.UserPostRank <= 5  
)
SELECT 
    fp.PostId,
    fp.Title,
    fp.CreationDate,
    fp.LastActivityDate,
    fp.Score,
    fp.TotalBounty,
    fp.CommentCount,
    fp.BadgeCount,
    CASE 
        WHEN fp.BadgeCount > 0 THEN 'Has Badges: ' || fp.BadgeNames
        ELSE 'No Badges'
    END AS BadgeInfo,
    CASE 
        WHEN fp.Score >= 10 THEN 'High Score'
        WHEN fp.Score >= 5 THEN 'Medium Score'
        ELSE 'Low Score'
    END AS ScoreCategory
FROM 
    FilteredPosts fp
WHERE 
    fp.TotalBounty > 0
ORDER BY 
    fp.TotalBounty DESC, fp.LastActivityDate DESC;
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        COALESCE(NULLIF(p.AcceptedAnswerId, -1), 0) AS AcceptedAnswerId,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 2) AS UpVotes,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1  
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.AcceptedAnswerId
),
BadgesWithUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        b.Name AS BadgeName,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName, b.Name
),
PostCommentLinks AS (
    SELECT 
        pl.PostId,
        COUNT(pl.RelatedPostId) AS RelatedPostsCount
    FROM 
        PostLinks pl
    GROUP BY 
        pl.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.CommentCount,
    rp.UpVotes,
    bwu.DisplayName AS UserName,
    bwu.BadgeName,
    bwu.BadgeCount,
    pcl.RelatedPostsCount,
    CASE 
        WHEN rp.AcceptedAnswerId IS NOT NULL AND rp.AcceptedAnswerId > 0 THEN 'Accepted'
        ELSE 'Not Accepted'
    END AS AnswerStatus
FROM 
    RankedPosts rp
LEFT JOIN 
    BadgesWithUsers bwu ON rp.PostId = bwu.UserId
LEFT JOIN 
    PostCommentLinks pcl ON rp.PostId = pcl.PostId
WHERE 
    rp.UserPostRank <= 5  
ORDER BY 
    rp.Score DESC, rp.CreationDate DESC
LIMIT 50;
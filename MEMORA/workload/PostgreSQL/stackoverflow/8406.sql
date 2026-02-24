
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostID,
        p.Title,
        p.CreationDate,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        COUNT(CASE WHEN c.Id IS NOT NULL THEN 1 END) AS CommentCount,
        COUNT(DISTINCT v.UserId) AS VoteCount,
        (SELECT COUNT(*) FROM Posts AS a WHERE a.ParentId = p.Id) AS AnswerCount
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    LEFT JOIN 
        Votes v ON v.PostId = p.Id AND v.VoteTypeId IN (2, 3)  
    WHERE 
        p.PostTypeId = 1  
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, u.DisplayName
), 
PostWithBadges AS (
    SELECT 
        rp.PostID,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.OwnerDisplayName,
        rp.CommentCount,
        rp.VoteCount,
        rp.AnswerCount,
        COUNT(b.Id) AS BadgeCount
    FROM 
        RankedPosts rp
    LEFT JOIN 
        Badges b ON b.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = rp.PostID)
    GROUP BY 
        rp.PostID, rp.Title, rp.CreationDate, rp.Score, rp.OwnerDisplayName, rp.CommentCount, rp.VoteCount, rp.AnswerCount
)
SELECT 
    pb.PostID,
    pb.Title,
    pb.CreationDate,
    pb.Score,
    pb.OwnerDisplayName,
    pb.CommentCount,
    pb.VoteCount,
    pb.AnswerCount,
    pb.BadgeCount,
    RANK() OVER (ORDER BY pb.Score DESC, pb.CreationDate ASC) AS ScoreRank
FROM 
    PostWithBadges pb
WHERE 
    pb.BadgeCount > 0  
ORDER BY 
    pb.Score DESC, 
    pb.BadgeCount DESC, 
    pb.CreationDate ASC;

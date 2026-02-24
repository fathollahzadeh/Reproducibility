
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Tags,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.Tags, p.CreationDate, p.ViewCount, p.Score, p.OwnerDisplayName
),

TopPosters AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS QuestionCount,
        SUM(p.Score) AS TotalScore,
        RANK() OVER (ORDER BY COUNT(DISTINCT p.Id) DESC) AS RankByQuestions
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        u.Id, u.DisplayName
),

PostStatistics AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Tags,
        rp.ViewCount,
        rp.Score,
        rp.OwnerDisplayName,
        tp.QuestionCount,
        tp.TotalScore,
        rp.CommentCount
    FROM 
        RankedPosts rp
    JOIN 
        TopPosters tp ON rp.OwnerDisplayName = tp.DisplayName
)

SELECT 
    ps.PostId,
    ps.Title,
    ps.Tags,
    ps.ViewCount,
    ps.Score,
    ps.CommentCount,
    ps.QuestionCount,
    ps.TotalScore,
    CASE 
        WHEN ps.CommentCount > 10 THEN 'Highly Discussed'
        WHEN ps.CommentCount BETWEEN 5 AND 10 THEN 'Moderately Discussed'
        ELSE 'Less Discussed'
    END AS DiscussionLevel
FROM 
    PostStatistics ps
WHERE 
    ps.TotalScore > 50 
ORDER BY 
    ps.Score DESC, ps.ViewCount DESC
LIMIT 10;

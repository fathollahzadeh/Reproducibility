
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        u.DisplayName AS Owner,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT a.Id) AS AnswerCount,
        MAX(ph.CreationDate) AS LastActivityDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY MAX(ph.CreationDate) DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId AND a.PostTypeId = 2
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.Body, p.Tags, u.DisplayName
),
PostDetails AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Body,
        rp.Tags,
        rp.Owner,
        rp.CommentCount,
        rp.AnswerCount,
        rp.LastActivityDate,
        pt.Name AS PostType,
        CASE 
            WHEN rp.CommentCount >= 5 THEN 'Highly Engaging'
            WHEN rp.AnswerCount >= 5 THEN 'Well-Answered'
            ELSE 'Needs Attention'
        END AS EngagementLevel
    FROM 
        RankedPosts rp
    JOIN 
        PostTypes pt ON pt.Id = 1 
    WHERE 
        rp.Rank = 1 
)
SELECT 
    pd.PostId,
    pd.Title,
    pd.Body,
    pd.Tags,
    pd.Owner,
    pd.CommentCount,
    pd.AnswerCount,
    pd.LastActivityDate,
    pd.PostType,
    pd.EngagementLevel,
    EXISTS (
        SELECT 1 FROM Votes v
        WHERE v.PostId = pd.PostId AND v.VoteTypeId = 2 
    ) AS HasUpvotes,
    (SELECT STRING_AGG(DISTINCT bt.Name, ', ') 
        FROM Badges b 
        JOIN Users u ON b.UserId = u.Id 
        JOIN PostHistoryTypes bt ON b.Class = bt.Id 
        WHERE u.DisplayName = pd.Owner) AS OwnerBadges
FROM 
    PostDetails pd
ORDER BY 
    pd.LastActivityDate DESC, 
    pd.CommentCount DESC;

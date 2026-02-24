WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        u.DisplayName AS OwnerName,
        p.Score,
        p.ViewCount,
        DENSE_RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year'
),
TopRankedPosts AS (
    SELECT 
        rp.* 
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 5
),
PostDetails AS (
    SELECT 
        trp.PostId,
        trp.Title,
        trp.OwnerName,
        COALESCE(pc.CommentCount, 0) AS CommentCount,
        COALESCE(ac.AnswerCount, 0) AS AnswerCount,
        COALESCE(b.BadgeCount, 0) AS BadgeCount
    FROM 
        TopRankedPosts trp
    LEFT JOIN 
        (SELECT PostId, COUNT(*) AS CommentCount FROM Comments GROUP BY PostId) pc ON trp.PostId = pc.PostId
    LEFT JOIN 
        (SELECT ParentId AS PostId, COUNT(*) AS AnswerCount FROM Posts WHERE PostTypeId = 2 GROUP BY ParentId) ac ON trp.PostId = ac.PostId
    LEFT JOIN 
        (SELECT UserId, COUNT(DISTINCT Id) AS BadgeCount FROM Badges GROUP BY UserId) b ON trp.OwnerName = (SELECT DisplayName FROM Users WHERE Id = b.UserId)
)
SELECT 
    PD.PostId,
    PD.Title,
    PD.OwnerName,
    PD.CommentCount,
    PD.AnswerCount,
    PD.BadgeCount,
    COUNT(DISTINCT v.Id) AS VoteCount
FROM 
    PostDetails PD
LEFT JOIN 
    Votes v ON PD.PostId = v.PostId
GROUP BY 
    PD.PostId, PD.Title, PD.OwnerName, PD.CommentCount, PD.AnswerCount, PD.BadgeCount
ORDER BY 
    PD.BadgeCount DESC, PD.CommentCount DESC;
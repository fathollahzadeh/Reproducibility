WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '6 months'
        AND p.ViewCount > 100
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        CreationDate,
        Score,
        ViewCount,
        AnswerCount,
        OwnerDisplayName
    FROM 
        RankedPosts
    WHERE 
        Rank <= 5
),
PostStatistics AS (
    SELECT 
        th.PostId,
        th.Title,
        th.CreationDate,
        th.Score,
        th.ViewCount,
        th.AnswerCount,
        COALESCE(c.CommentCount, 0) AS CommentCount,
        COALESCE(b.BadgeCount, 0) AS BadgeCount
    FROM 
        TopPosts th
    LEFT JOIN (
        SELECT 
            PostId, 
            COUNT(*) AS CommentCount 
        FROM 
            Comments 
        GROUP BY 
            PostId
    ) c ON th.PostId = c.PostId
    LEFT JOIN (
        SELECT 
            UserId, 
            COUNT(*) AS BadgeCount 
        FROM 
            Badges 
        GROUP BY 
            UserId
    ) b ON b.UserId = (
        SELECT 
            OwnerUserId 
        FROM 
            Posts 
        WHERE 
            Id = th.PostId
    )
)
SELECT 
    ps.PostId,
    ps.Title,
    ps.CreationDate,
    ps.Score,
    ps.ViewCount,
    ps.AnswerCount,
    ps.CommentCount,
    ps.BadgeCount,
    pht.Name AS PostHistoryType,
    COUNT(phe.Id) AS RevisionCount
FROM 
    PostStatistics ps
LEFT JOIN 
    PostHistory phe ON ps.PostId = phe.PostId
LEFT JOIN 
    PostHistoryTypes pht ON phe.PostHistoryTypeId = pht.Id
GROUP BY 
    ps.PostId, ps.Title, ps.CreationDate, ps.Score, ps.ViewCount, ps.AnswerCount, ps.CommentCount, ps.BadgeCount, pht.Name
ORDER BY 
    ps.Score DESC, ps.ViewCount DESC;
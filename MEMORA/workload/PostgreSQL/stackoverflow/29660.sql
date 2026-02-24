
WITH RecentPostActivities AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        ph.UserDisplayName AS LastEditor,
        ph.CreationDate AS LastEditDate,
        ph.Comment AS EditComment,
        STRING_AGG(DISTINCT tg.TagName, ', ') AS Tags,
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId 
            AND ph.CreationDate = (
                SELECT MAX(ph_sub.CreationDate) 
                FROM PostHistory ph_sub 
                WHERE ph_sub.PostId = p.Id AND ph_sub.PostHistoryTypeId IN (4, 5, 6)
            )
    LEFT JOIN 
        Tags tg ON tg.ExcerptPostId = p.Id
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, ph.UserDisplayName, ph.CreationDate, ph.Comment
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        CreationDate,
        ViewCount,
        LastEditor,
        LastEditDate,
        EditComment,
        Tags,
        CommentCount,
        RANK() OVER (ORDER BY ViewCount DESC) AS ViewRank
    FROM 
        RecentPostActivities
)
SELECT 
    p.Title,
    p.CreationDate,
    p.ViewCount,
    p.LastEditor,
    p.LastEditDate,
    p.EditComment,
    p.Tags,
    p.CommentCount
FROM 
    TopPosts p
WHERE 
    p.ViewRank <= 10
ORDER BY 
    p.ViewCount DESC;

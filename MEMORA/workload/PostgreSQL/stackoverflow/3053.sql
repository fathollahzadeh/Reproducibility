WITH RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.CreationDate,
        COUNT(cm.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount,
        ROW_NUMBER() OVER (ORDER BY p.CreationDate DESC) AS rn
    FROM Posts p
    LEFT JOIN Comments cm ON p.Id = cm.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days'
    GROUP BY p.Id, p.Title, p.ViewCount, p.CreationDate
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.ViewCount,
        rp.CommentCount,
        rp.UpVoteCount,
        rp.DownVoteCount,
        CASE 
            WHEN rp.UpVoteCount > COALESCE(rp.DownVoteCount, 0) THEN 'Positive'
            ELSE 'Negative'
        END AS Sentiment
    FROM RecentPosts rp
    WHERE rp.rn <= 10
)
SELECT 
    tp.Title,
    tp.ViewCount,
    tp.CommentCount,
    tp.UpVoteCount,
    tp.DownVoteCount,
    tp.Sentiment,
    CASE 
        WHEN tp.CommentCount > 0 THEN 'Has Comments'
        ELSE 'No Comments'
    END AS Comment_Status
FROM TopPosts tp
ORDER BY tp.ViewCount DESC;
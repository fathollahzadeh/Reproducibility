
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.PostTypeId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS UserRank,
        COALESCE(pc.ClosedDate, '9999-12-31') AS LastClosedDate,
        ARRAY_AGG(DISTINCT t.TagName) AS TagsArray
    FROM 
        Posts p
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId AND ph.PostHistoryTypeId IN (10, 11)  
    LEFT JOIN 
        Posts pc ON p.Id = pc.AcceptedAnswerId
    LEFT JOIN 
        Tags t ON t.ExcerptPostId = p.Id
    WHERE 
        p.CreationDate > (CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year')
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, p.PostTypeId, pc.ClosedDate
),
HighScoringPosts AS (
    SELECT 
        *,
        CASE 
            WHEN UserRank = 1 THEN 'Top Post'
            WHEN UserRank <= 5 THEN 'High Performer'
            ELSE 'Regular'
        END AS PostCategory
    FROM 
        RankedPosts
    WHERE 
        Score IS NOT NULL
),
SubqueryPostStats AS (
    SELECT 
        p.Id AS PostId,
        COUNT(DISTINCT c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id
)
SELECT 
    h.PostId,
    h.Title,
    h.CreationDate,
    h.Score,
    h.ViewCount,
    h.PostCategory,
    ps.CommentCount,
    ps.UpVotes,
    ps.DownVotes,
    h.LastClosedDate,
    h.TagsArray
FROM 
    HighScoringPosts h
INNER JOIN 
    SubqueryPostStats ps ON h.PostId = ps.PostId
WHERE 
    h.PostCategory IN ('Top Post', 'High Performer')
ORDER BY 
    h.Score DESC, h.CreationDate DESC
LIMIT 100;

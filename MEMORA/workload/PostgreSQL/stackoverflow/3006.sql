
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        u.Reputation,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year' 
        AND (p.ViewCount > 0 OR p.Score > 0)
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score, u.Reputation
),
FilteredPosts AS (
    SELECT 
        PostId,
        Title,
        CreationDate,
        ViewCount,
        Score,
        Reputation,
        UserPostRank,
        CommentCount,
        UpVotes,
        DownVotes,
        CASE 
            WHEN UserPostRank = 1 THEN 'Most Recent Post'
            ELSE 'Other Posts' 
        END AS PostCategory
    FROM 
        RankedPosts
    WHERE 
        Reputation IS NOT NULL AND Reputation > 100
),
FinalResults AS (
    SELECT 
        fp.*, 
        CASE 
            WHEN fp.Score > 10 THEN 'Highly Engaging' 
            WHEN fp.Score BETWEEN 5 AND 10 THEN 'Moderately Engaging' 
            ELSE 'Less Engaging' 
        END AS EngagementLevel,
        COALESCE(fp.UpVotes - fp.DownVotes, 0) AS NetVotes
    FROM 
        FilteredPosts fp
)
SELECT 
    p.*, 
    pt.Name AS PostType,
    COALESCE(ph.Comment, 'No Comments') AS LastActionComment
FROM 
    FinalResults p
LEFT JOIN 
    PostTypes pt ON EXISTS (SELECT 1 FROM Posts WHERE Id = p.PostId AND PostTypeId = pt.Id)
LEFT JOIN 
    PostHistory ph ON p.PostId = ph.PostId AND ph.CreationDate = (
        SELECT MAX(CreationDate) 
        FROM PostHistory 
        WHERE PostId = p.PostId AND PostHistoryTypeId IN (24, 10, 11)
    )
WHERE 
    p.CommentCount > 0 OR p.EngagementLevel = 'Highly Engaging'
ORDER BY 
    p.CreationDate DESC
LIMIT 100;


WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS Rank
    FROM 
        Posts p
        LEFT JOIN Users u ON p.OwnerUserId = u.Id
        LEFT JOIN Comments c ON p.Id = c.PostId
        LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, u.DisplayName, p.PostTypeId
), 
TopPosts AS (
    SELECT 
        rp.*, 
        (UpVoteCount - DownVoteCount) AS NetVoteScore,
        CASE 
            WHEN p.PostTypeId = 1 THEN 'Question'
            WHEN p.PostTypeId = 2 THEN 'Answer'
            ELSE 'Other'
        END AS PostType
    FROM 
        RankedPosts rp
        JOIN Posts p ON rp.PostId = p.Id
    WHERE 
        Rank <= 10
)
SELECT 
    PostId,
    Title,
    CreationDate,
    OwnerDisplayName,
    CommentCount,
    UpVoteCount,
    DownVoteCount,
    NetVoteScore,
    PostType
FROM 
    TopPosts
ORDER BY 
    NetVoteScore DESC, 
    CreationDate DESC;

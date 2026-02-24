
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        u.DisplayName AS OwnerName,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate > (CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year')
    GROUP BY 
        p.Id, p.Title, p.CreationDate, u.DisplayName
),
TopPosts AS (
    SELECT 
        PostId, Title, OwnerName, CreationDate, CommentCount
    FROM 
        RankedPosts
    WHERE 
        rn = 1
),
PostVoteSummary AS (
    SELECT 
        v.PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes v
    GROUP BY 
        v.PostId
)
SELECT 
    t.PostId,
    t.Title,
    t.OwnerName,
    t.CreationDate,
    COALESCE(pv.UpVotes, 0) AS TotalUpVotes,
    COALESCE(pv.DownVotes, 0) AS TotalDownVotes,
    t.CommentCount,
    CASE 
        WHEN t.CommentCount = 0 THEN 'No Comments'
        WHEN t.CommentCount > 0 AND t.CommentCount <= 5 THEN 'Few Comments'
        ELSE 'Many Comments'
    END AS CommentStatus
FROM 
    TopPosts t
LEFT JOIN 
    PostVoteSummary pv ON t.PostId = pv.PostId
WHERE 
    EXISTS (
        SELECT 1
        FROM Posts p
        WHERE p.AcceptedAnswerId IS NOT NULL 
        AND p.Id = t.PostId
    )
ORDER BY 
    t.CreationDate DESC
LIMIT 10;

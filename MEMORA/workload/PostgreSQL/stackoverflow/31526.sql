
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.OwnerUserId,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id, p.Title, p.Body, p.OwnerUserId, u.DisplayName
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Body,
        rp.OwnerDisplayName,
        rp.CommentCount,
        rp.UpVotes,
        rp.DownVotes
    FROM 
        RankedPosts rp
    WHERE 
        rp.PostRank = 1
),
PostStats AS (
    SELECT 
        tp.*,
        (tp.UpVotes - tp.DownVotes) AS NetVotes,
        (SELECT COUNT(*) FROM Posts p WHERE p.AcceptedAnswerId = tp.PostId) AS AnswersCount
    FROM 
        TopPosts tp
)
SELECT 
    ps.PostId,
    ps.Title,
    ps.OwnerDisplayName,
    ps.CommentCount,
    ps.UpVotes,
    ps.DownVotes,
    ps.NetVotes,
    ps.AnswersCount,
    CASE 
        WHEN ps.NetVotes > 10 THEN 'Hot'
        WHEN ps.NetVotes BETWEEN 1 AND 10 THEN 'Warm'
        ELSE 'Cold'
    END AS PostTemperature,
    (SELECT STRING_AGG(tag.TagName, ', ') 
     FROM Tags tag 
     JOIN Posts p ON tag.ExcerptPostId = p.Id 
     WHERE p.Id = ps.PostId) AS Tags
FROM 
    PostStats ps
WHERE 
    ps.CommentCount > 5
ORDER BY 
    ps.NetVotes DESC, ps.PostId ASC;

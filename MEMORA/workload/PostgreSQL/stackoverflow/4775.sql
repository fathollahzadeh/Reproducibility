
WITH RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= '2024-10-01 12:34:56'::timestamp - INTERVAL '30 days'
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.OwnerDisplayName
    FROM 
        RecentPosts rp
    WHERE 
        rp.PostRank = 1
),
PostStats AS (
    SELECT 
        p.Id AS PostId,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COUNT(c.Id) AS CommentCount,
        p.ViewCount,
        p.AcceptedAnswerId
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    GROUP BY 
        p.Id, p.ViewCount, p.AcceptedAnswerId
),
FinalResults AS (
    SELECT 
        tp.Title,
        ps.UpVotes,
        ps.DownVotes,
        ps.CommentCount,
        CASE 
            WHEN ps.AcceptedAnswerId IS NOT NULL THEN 'Accepted'
            ELSE 'Not Accepted'
        END AS AnswerStatus
    FROM 
        TopPosts tp
    JOIN 
        PostStats ps ON tp.PostId = ps.PostId
)
SELECT 
    fr.Title,
    fr.UpVotes,
    fr.DownVotes,
    fr.CommentCount,
    fr.AnswerStatus,
    CASE 
        WHEN fr.UpVotes > fr.DownVotes THEN 'Positive' 
        WHEN fr.UpVotes < fr.DownVotes THEN 'Negative'
        ELSE 'Neutral'
    END AS VoteSentiment
FROM 
    FinalResults fr
ORDER BY 
    fr.UpVotes DESC, fr.CommentCount DESC
LIMIT 10;

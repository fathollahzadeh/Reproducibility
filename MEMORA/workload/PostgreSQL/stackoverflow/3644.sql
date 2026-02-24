WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.OwnerUserId
),
FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.PostRank,
        rp.CommentCount,
        rp.UpVotes,
        rp.DownVotes,
        CASE 
            WHEN rp.UpVotes > rp.DownVotes THEN 'Positive'
            WHEN rp.UpVotes < rp.DownVotes THEN 'Negative'
            ELSE 'Neutral'
        END AS VoteSentiment
    FROM 
        RankedPosts rp
    WHERE 
        rp.CommentCount > 5 AND
        rp.PostRank <= 3
)
SELECT 
    fp.PostId,
    fp.Title,
    fp.CreationDate,
    fp.VoteSentiment,
    COALESCE(NULLIF(fp.UpVotes - fp.DownVotes, 0), NULL) AS EffectiveVotes,
    CONCAT('Post ID: ', fp.PostId, ' — Title: ', fp.Title) AS PostSummary
FROM 
    FilteredPosts fp
ORDER BY 
    fp.CreationDate DESC
LIMIT 10;
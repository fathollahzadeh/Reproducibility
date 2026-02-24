WITH RankedPosts AS (
    SELECT 
        p.Id AS PostID,
        p.Title,
        p.Score,
        u.DisplayName AS Author,
        ROW_NUMBER() OVER(PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank,
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    GROUP BY 
        p.Id, p.Title, p.Score, u.DisplayName, p.PostTypeId
),
HighScoringPosts AS (
    SELECT 
        PostID, 
        Title, 
        Score, 
        Author,
        CommentCount
    FROM 
        RankedPosts
    WHERE 
        Rank <= 5
),
PostVotes AS (
    SELECT 
        p.Id AS PostID,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        SUM(CASE WHEN v.VoteTypeId IN (6, 10) THEN 1 ELSE 0 END) AS CloseVotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id
)
SELECT 
    hp.PostID,
    hp.Title,
    hp.Score,
    hp.Author,
    hp.CommentCount,
    pv.UpVotes,
    pv.DownVotes,
    pv.CloseVotes,
    CASE 
        WHEN pv.UpVotes > pv.DownVotes THEN 'Positive' 
        WHEN pv.UpVotes < pv.DownVotes THEN 'Negative' 
        ELSE 'Neutral'
    END AS PostSentiment
FROM 
    HighScoringPosts hp
JOIN 
    PostVotes pv ON hp.PostID = pv.PostID
ORDER BY 
    hp.Score DESC, hp.CommentCount DESC
;

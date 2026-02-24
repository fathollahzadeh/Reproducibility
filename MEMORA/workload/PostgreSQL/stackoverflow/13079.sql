WITH PostEngagement AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS VoteCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id, p.Title, p.CreationDate
),
PostStatistics AS (
    SELECT
        pe.PostId,
        pe.Title,
        pe.CreationDate,
        pe.CommentCount,
        pe.VoteCount,
        pe.UpVotes,
        pe.DownVotes,
        CASE 
            WHEN pe.UpVotes > pe.DownVotes THEN 'Positive'
            WHEN pe.DownVotes > pe.UpVotes THEN 'Negative'
            ELSE 'Neutral'
        END AS PostSentiment
    FROM 
        PostEngagement pe
)

SELECT 
    ps.PostId,
    ps.Title,
    ps.CreationDate,
    ps.CommentCount,
    ps.VoteCount,
    ps.UpVotes,
    ps.DownVotes,
    ps.PostSentiment,
    (ps.UpVotes - ps.DownVotes) AS NetVotes
FROM 
    PostStatistics ps
ORDER BY 
    NetVotes DESC, ps.CreationDate DESC;
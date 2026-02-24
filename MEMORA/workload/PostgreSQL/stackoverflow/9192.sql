WITH RankedVotes AS (
    SELECT 
        p.Id AS PostId,
        COUNT(v.Id) AS VoteCount,
        SUM(CASE WHEN vt.Name = 'UpMod' THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN vt.Name = 'DownMod' THEN 1 ELSE 0 END) AS DownVotes,
        ROW_NUMBER() OVER (ORDER BY COUNT(v.Id) DESC) AS VoteRank
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        VoteTypes vt ON v.VoteTypeId = vt.Id
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    GROUP BY 
        p.Id
),

MostVotedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        uv.DisplayName AS UserOwner,
        r.VoteCount,
        r.UpVotes,
        r.DownVotes
    FROM 
        RankedVotes r
    JOIN 
        Posts p ON r.PostId = p.Id
    JOIN 
        Users uv ON p.OwnerUserId = uv.Id
    WHERE 
        r.VoteRank <= 10
)

SELECT 
    mv.PostId,
    mv.Title,
    mv.CreationDate,
    mv.UserOwner,
    mv.VoteCount,
    mv.UpVotes,
    mv.DownVotes,
    COUNT(c.Id) AS CommentCount
FROM 
    MostVotedPosts mv
LEFT JOIN 
    Comments c ON mv.PostId = c.PostId
GROUP BY 
    mv.PostId, mv.Title, mv.CreationDate, mv.UserOwner, mv.VoteCount, mv.UpVotes, mv.DownVotes
ORDER BY 
    mv.VoteCount DESC;
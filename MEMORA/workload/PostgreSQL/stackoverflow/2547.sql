WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount,
        SUM(CASE WHEN p.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS HasAcceptedAnswer
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    GROUP BY 
        p.Id
),
RankedPosts AS (
    SELECT 
        ps.PostId,
        ps.CommentCount,
        ps.UpVoteCount,
        ps.DownVoteCount,
        ps.HasAcceptedAnswer,
        ROW_NUMBER() OVER (ORDER BY ps.UpVoteCount DESC, ps.CommentCount DESC) AS PostRank
    FROM 
        PostStats ps
)
SELECT 
    r.PostId,
    r.CommentCount,
    r.UpVoteCount,
    r.DownVoteCount,
    r.HasAcceptedAnswer,
    COALESCE(p.Title, 'Deleted Post') AS PostTitle,
    u.DisplayName AS OwnerDisplayName,
    r.PostRank,
    CASE 
        WHEN r.HasAcceptedAnswer = 1 THEN 'Yes' 
        ELSE 'No' 
    END AS AcceptedAnswerStatus
FROM 
    RankedPosts r
LEFT JOIN 
    Posts p ON r.PostId = p.Id
LEFT JOIN 
    Users u ON p.OwnerUserId = u.Id
WHERE 
    r.PostRank <= 50
ORDER BY 
    r.PostRank;
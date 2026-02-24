WITH UserReputation AS (
    SELECT 
        Id AS UserId,
        Reputation,
        CreationDate,
        LastAccessDate,
        UpVotes,
        DownVotes,
        Views,
        (UpVotes - DownVotes) AS NetVotes
    FROM 
        Users
),
PostSummary AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.PostTypeId,
        p.CreationDate,
        p.ViewCount,
        COALESCE(a.AcceptedAnswerId, 0) AS AcceptedAnswerId,
        COALESCE(c.CommentCount, 0) AS CommentCount,
        COALESCE(v.VoteCount, 0) AS VoteCount
    FROM 
        Posts p
    LEFT JOIN 
        (SELECT PostId, COUNT(*) AS CommentCount FROM Comments GROUP BY PostId) c ON p.Id = c.PostId
    LEFT JOIN 
        (SELECT PostId, COUNT(*) AS VoteCount FROM Votes GROUP BY PostId) v ON p.Id = v.PostId
    LEFT JOIN 
        (SELECT Id, AcceptedAnswerId FROM Posts) a ON p.Id = a.Id
),
TagSummary AS (
    SELECT 
        Id AS TagId,
        TagName,
        Count AS PostCount
    FROM 
        Tags
)


SELECT 
    u.UserId,
    u.Reputation,
    ps.PostId,
    ps.Title,
    ps.ViewCount,
    ps.CommentCount,
    ps.VoteCount,
    ts.TagId,
    ts.TagName,
    ts.PostCount,
    ps.CreationDate
FROM 
    UserReputation u
JOIN 
    PostSummary ps ON u.UserId = ps.AcceptedAnswerId
JOIN 
    PostLinks pl ON ps.PostId = pl.PostId
JOIN 
    TagSummary ts ON pl.RelatedPostId = ts.TagId
ORDER BY 
    u.Reputation DESC, ps.ViewCount DESC;
WITH RecursiveCTE AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        COALESCE(An.AnswerCount, 0) AS AnswerCount,
        COALESCE(Com.CommentCount, 0) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY p.CreationDate DESC) AS RowNum
    FROM 
        Posts p
    LEFT JOIN (
        SELECT 
            ParentId,
            COUNT(*) AS AnswerCount
        FROM 
            Posts
        WHERE 
            PostTypeId = 2 
        GROUP BY 
            ParentId
    ) An ON p.Id = An.ParentId
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(*) AS CommentCount
        FROM 
            Comments
        GROUP BY 
            PostId
    ) Com ON p.Id = Com.PostId
    WHERE 
        p.PostTypeId = 1
),
UserScoreSummary AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(v.BountyAmount) AS TotalBounty,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        COUNT(DISTINCT CASE WHEN v.VoteTypeId = 2 THEN v.PostId END) AS UniqueUpVotedPosts
    FROM 
        Users u
    LEFT JOIN Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    r.PostId,
    r.Title,
    r.CreationDate,
    r.ViewCount,
    r.Score,
    r.AnswerCount,
    r.CommentCount,
    u.DisplayName AS UserCreator,
    u.TotalBounty AS CreatorTotalBounty,
    u.UpVotes AS CreatorUpVotes,
    u.UniqueUpVotedPosts AS CreatorUniqueUpVotedPosts,
    (
        SELECT 
            COUNT(*) 
        FROM 
            Votes v
        WHERE 
            v.PostId = r.PostId AND v.VoteTypeId = 3
    ) AS DownVotes
FROM 
    RecursiveCTE r
LEFT JOIN UserScoreSummary u ON r.PostId = u.UserId
WHERE 
    r.ViewCount > 1000
ORDER BY 
    r.Score DESC,
    r.ViewCount DESC
OFFSET 0 ROWS 
FETCH NEXT 10 ROWS ONLY;

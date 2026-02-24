
WITH UserReputation AS (
    SELECT 
        Id AS UserId,
        Reputation,
        ROW_NUMBER() OVER (ORDER BY Reputation DESC) AS ReputationRank
    FROM Users
),
PostDetails AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.CreationDate,
        COALESCE(ph.Comment, 'No Comments') AS PostHistoryComment,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        RANK() OVER (ORDER BY p.ViewCount DESC) AS ViewRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    LEFT JOIN 
        Votes v ON v.PostId = p.Id
    LEFT JOIN 
        PostHistory ph ON ph.PostId = p.Id AND ph.PostHistoryTypeId IN (10, 11)
    GROUP BY 
        p.Id, p.Title, p.ViewCount, p.CreationDate, ph.Comment
),
TopPosts AS (
    SELECT 
        pd.PostId,
        pd.Title,
        pd.ViewCount,
        pd.CreationDate,
        pd.PostHistoryComment,
        pd.CommentCount,
        pd.UpVotes,
        pd.DownVotes,
        CASE 
            WHEN pd.CommentCount > 0 THEN ROUND(COALESCE(pd.UpVotes, 0) / NULLIF(pd.CommentCount, 0), 2)
            ELSE 0
        END AS UpVoteToCommentRatio,
        RANK() OVER (ORDER BY pd.UpVotes DESC) AS TopRank
    FROM 
        PostDetails pd
    WHERE 
        pd.ViewRank <= 100
),
UserTopPosts AS (
    SELECT 
        ur.UserId,
        ur.Reputation,
        tp.Title,
        tp.UpVotes,
        tp.CommentCount,
        tp.UpVoteToCommentRatio
    FROM 
        UserReputation ur
    JOIN 
        Posts p ON p.OwnerUserId = ur.UserId
    JOIN 
        TopPosts tp ON tp.PostId = p.Id
)
SELECT 
    utp.UserId,
    u.DisplayName,
    utp.Reputation,
    ARRAY_AGG(utp.Title) AS PostTitles,
    SUM(utp.UpVotes) AS TotalUpVotes,
    SUM(utp.CommentCount) AS TotalComments,
    AVG(utp.UpVoteToCommentRatio) AS AvgUpVoteToCommentRatio
FROM 
    UserTopPosts utp
JOIN 
    Users u ON u.Id = utp.UserId
GROUP BY 
    utp.UserId, u.DisplayName, utp.Reputation
HAVING 
    AVG(utp.UpVoteToCommentRatio) > 1.5
ORDER BY 
    TotalUpVotes DESC
LIMIT 10;

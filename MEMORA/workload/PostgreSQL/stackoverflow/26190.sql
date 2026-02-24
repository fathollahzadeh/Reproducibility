
WITH PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.OwnerUserId,
        p.Score,
        p.ViewCount,
        STRING_AGG(t.TagName, ', ') AS TagsList
    FROM 
        Posts p
    LEFT JOIN 
        Tags t ON POSITION(t.TagName IN p.Tags) > 0
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, p.OwnerUserId, p.Score, p.ViewCount
),

UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS QuestionsAsked,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpvotesReceived 
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON v.PostId = p.Id
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),

HighlyVotedPosts AS (
    SELECT 
        pd.PostId,
        pd.Title,
        pd.Body,
        pd.CreationDate,
        pd.ViewCount,
        u.DisplayName AS OwnerName,
        u.UserId,
        u.Reputation,
        COUNT(v.Id) AS VoteCount
    FROM 
        PostDetails pd
    JOIN 
        Votes v ON pd.PostId = v.PostId
    JOIN 
        UserReputation u ON pd.OwnerUserId = u.UserId
    WHERE 
        v.VoteTypeId IN (2, 3) 
    GROUP BY 
        pd.PostId, pd.Title, pd.Body, pd.CreationDate, pd.ViewCount, u.DisplayName, u.UserId, u.Reputation
    HAVING 
        COUNT(v.Id) > 10 
)

SELECT 
    hpp.PostId,
    hpp.Title,
    hpp.Body,
    hpp.CreationDate,
    hpp.ViewCount,
    hpp.OwnerName,
    hpp.Reputation,
    hpp.VoteCount,
    pd.TagsList
FROM 
    HighlyVotedPosts hpp
JOIN 
    PostDetails pd ON hpp.PostId = pd.PostId
ORDER BY 
    hpp.VoteCount DESC, hpp.Reputation DESC;

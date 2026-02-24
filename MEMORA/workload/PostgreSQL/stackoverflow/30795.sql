
WITH RECURSIVE UserHierarchy AS (
    SELECT Id, DisplayName, Reputation, CreationDate, 
           CAST(DisplayName AS VARCHAR(255)) AS Path
    FROM Users
    WHERE Id = 1  
    
    UNION ALL
    
    SELECT u.Id, u.DisplayName, u.Reputation, u.CreationDate,
           CONCAT(uh.Path, ' -> ', u.DisplayName)
    FROM Users u
    JOIN UserHierarchy uh ON u.Id = uh.Id + 1  
),
PostData AS (
    SELECT p.Id AS PostId, 
           p.Title, 
           p.CreationDate,
           COALESCE(p.AcceptedAnswerId, 0) AS AcceptedAnswerId,
           COUNT(c.Id) AS CommentCount,
           SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
           SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
           COUNT(DISTINCT b.Id) AS BadgeCount,
           p.OwnerUserId
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    LEFT JOIN Badges b ON p.OwnerUserId = b.UserId
    WHERE p.CreationDate >= CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year'
    GROUP BY p.Id, p.Title, p.CreationDate, p.AcceptedAnswerId, p.OwnerUserId
),
RankedPosts AS (
    SELECT pd.*, 
           RANK() OVER (ORDER BY pd.UpVotes DESC, pd.CommentCount DESC) AS VoteRank
    FROM PostData pd
)
SELECT up.DisplayName, 
       rp.Title, 
       rp.CreationDate, 
       rp.CommentCount, 
       rp.UpVotes, 
       rp.DownVotes, 
       rp.BadgeCount, 
       CASE 
           WHEN rp.AcceptedAnswerId > 0 THEN 'Yes' 
           ELSE 'No' 
       END AS HasAcceptedAnswer,
       uh.Path
FROM RankedPosts rp
JOIN Users up ON rp.OwnerUserId = up.Id
JOIN UserHierarchy uh ON up.Id = uh.Id
WHERE rp.VoteRank <= 10
ORDER BY rp.VoteRank;

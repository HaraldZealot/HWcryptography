import std.stdio;
import std.algorithm;
import std.range;
import std.array;

int main(string[] args)
{
	if(args.length <= 1)
	{
		stderr.writeln("Too few arguments");
		return 1;
	}

	ubyte[][] messages;
	foreach(fileName; args[1..$])
		messages ~= cast(ubyte[])File(fileName, "rb")
		            .byChunk(4096)
		            .joiner
		            .array
		            .chunks(2)
		            .map!convertHumanReadableToBinary
		            .array;

	auto countOfMessages = messages.length;
	
	auto maxLength = messages[0].length;
	auto minLength = messages[0].length;
	
	foreach(message; messages)
	{
		if(maxLength < message.length)
			maxLength = message.length;
		if(minLength > message.length)
			minLength = message.length;
	}

	auto key = new ubyte[maxLength];

	foreach(k; 0..minLength)
	{
		auto hist = new int[countOfMessages];
		foreach(i; 0..countOfMessages)
		{
			foreach(j; 0..countOfMessages)
			{
				auto xorSymbol = messages[i][k] ^ messages[j][k];
				if((xorSymbol >= 0x41 && xorSymbol <= 0x5a)
				   || (xorSymbol >= 0x61 && xorSymbol <= 0x7a))
				{
					++hist[i];
				}
			}
		}

		size_t indexOfMax = 0u;
		foreach(i; 1..countOfMessages)
			if(hist[indexOfMax] < hist[i])
				indexOfMax = i;

		key[k] = messages[indexOfMax][k] ^ cast(ubyte)' ';
	}
	
	writeln(key);
	
	writeln("\n\n\n");
	
	key[34] = messages[0][34] ^ cast(ubyte)'u';
	key[35] = messages[0][35] ^ cast(ubyte)'a';

	foreach(i;0..countOfMessages-1)
	{
		char[] guessText = new char[messages[i].length];
		foreach(j; 0..guessText.length)
			guessText[j] = cast(char)(messages[i][j] ^ key[j]);
		writeln(guessText);
		writeln(guessText[34..36]);
	}

	writeln("\n\n\n");
	
	char[] plainText = new char[messages[$-1].length];
	
	foreach(i; 0..plainText.length)
		plainText[i] = cast(char)(messages[$-1][i] ^ key[i]);

	writeln(plainText);

	/+foreach(i; 0..countOfMessages)
	{
		foreach(j; 0..countOfMessages)
		{
			auto limit = min(messages[i].length, messages[j].length);
			foreach(k; 0..limit)
			{
				auto xorSymbol = messages[i][k] ^ messages[j][k];
				if((xorSymbol >= 0x41 && xorSymbol <= 0x5a)
				   || (xorSymbol >= 0x61 && xorSymbol <= 0x7a))
					writef("%c", cast(char)xorSymbol);
				else
					write("?");
			}
			writeln();
		}
		writeln();
	}+/

	/+foreach(message; messages)
	{
		message.each!(a => writef("%02x", a));
		writeln();
	}+/
	
	return 0;
}

ubyte convertHumanReadableToBinary(ubyte[] pair)
in
{
	assert(pair.length == 2, "convertHumanReadableToBinary expcects pair of ubyte");
}
body
{
	enum ubyte[ubyte] aMap = ['0':0, '1':1, '2':2, '3':3, '4':4, '5':5, '6':6, '7':7, '8':8, '9':9,
	                          'A':0xa, 'B':0xb, 'C':0xc, 'D':0xd, 'E':0xe, 'F':0xf, 
	                          'a':0xa, 'b':0xb, 'c':0xc, 'd':0xd, 'e':0xe, 'f':0xf];
	return cast(ubyte)(aMap[pair[0]]<<4 | aMap[pair[1]]);
}